# Arr media stack — wraps the nixflix flake input (declarative Servarr provisioning via
# each app's REST API) behind this repo's normal homelab.services.arr.* convention.
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.arr;
  caddyEnabled = config.homelab.services.caddy.enable;
  resticEnabled = config.homelab.services.restic.enable;
  domain = config.networking.domain;

  # Nixflix exposes Lidarr's host, media-management, metadata, and quality
  # endpoints declaratively, but it has no Lidarr config/naming option. Keep
  # this small reconciler for the API-only naming settings.
  lidarrNamingScript = pkgs.writeShellScript "lidarr-naming" ''
    set -euo pipefail

    api="http://127.0.0.1:${toString config.nixflix.lidarr.config.hostConfig.port}/api/v1"
    api_key="$(cat ${lib.escapeShellArg config.sops.secrets."arr/lidarr/api-key".path})"

    for attempt in $(seq 1 90); do
      if naming="$(curl --fail --silent --show-error \
        -H "X-Api-Key: $api_key" \
        "$api/config/naming" 2>/dev/null)"; then
        updated="$(printf '%s' "$naming" | ${pkgs.jq}/bin/jq '. + {
          renameTracks: true,
          replaceIllegalCharacters: true,
          standardTrackFormat: "{Album CleanTitle} ({Release Year})/{Artist CleanName} - {Album CleanTitle} - {track:00} - {Track CleanTitle}",
          multiDiscTrackFormat: "{Album CleanTitle} ({Release Year})/{Medium Format} {medium:00}/{Artist CleanName} - {Album CleanTitle} - {track:00} - {Track CleanTitle}",
          artistFolderFormat: "{Artist CleanName}"
        }')"

        curl --fail --silent --show-error \
          -X PUT \
          -H "X-Api-Key: $api_key" \
          -H "Content-Type: application/json" \
          --data-raw "$updated" \
          "$api/config/naming" >/dev/null
        exit 0
      fi
      echo "Waiting for Lidarr API... ($attempt/90)" >&2
      sleep 1
    done

    echo "Lidarr API not available after 90 seconds" >&2
    exit 1
  '';

  # Keep the custom-format definitions aligned with the release names Lidarr
  # actually receives. These formats are created separately from quality
  # profiles, so reconcile their expressions by name while preserving their
  # existing IDs and UI metadata.
  lidarrCustomFormatsScript = pkgs.writeShellScript "lidarr-custom-formats" ''
    set -euo pipefail

    api="http://127.0.0.1:${toString config.nixflix.lidarr.config.hostConfig.port}/api/v1"
    api_key="$(cat ${lib.escapeShellArg config.sops.secrets."arr/lidarr/api-key".path})"

    for attempt in $(seq 1 90); do
      if formats="$(${pkgs.curl}/bin/curl --fail --silent --show-error \
        -H "X-Api-Key: $api_key" \
        "$api/customformat" 2>/dev/null)"; then
        for name in CD Lossless Vinyl; do
          format_id="$(printf '%s' "$formats" | ${pkgs.jq}/bin/jq -r --arg name "$name" \
            '.[] | select(.name == $name) | .id')"

          if [ -z "$format_id" ]; then
            echo "Lidarr custom format not found: $name" >&2
            exit 1
          fi

          updated="$(printf '%s' "$formats" | ${pkgs.jq}/bin/jq -c --arg name "$name" '
            map(select(.name == $name) |
              if .name == "CD" then
                .specifications[0].fields[0].value = "(?:\\bCD\\b|\\b[0-9]+[- ]?CD\\b)"
              elif .name == "Lossless" then
                .specifications[0].fields[0].value = "\\b(?:FLAC|ALAC|APE|WAV|WavPack|lossless)\\b"
              elif .name == "Vinyl" then
                .specifications[0].fields[0].value = "\\b(?:Vinyl|[0-9]*LP|NeedleDrop)\\b"
              else
                .
              end
            ) | .[0]')"

          ${pkgs.curl}/bin/curl --fail --silent --show-error \
            -X PUT \
            -H "X-Api-Key: $api_key" \
            -H "Content-Type: application/json" \
            --data-raw "$updated" \
            "$api/customformat/$format_id" >/dev/null
        done
        exit 0
      fi
      echo "Waiting for Lidarr API... ($attempt/90)" >&2
      sleep 1
    done

    echo "Lidarr API not available after 90 seconds" >&2
    exit 1
  '';

  ldapCfg = cfg.jellyfin.ldap;
  ldapGroupDn = group: "cn=${group},ou=groups,${ldapCfg.baseDn}";
  ldapSearchFilter = "(|${lib.concatMapStringsSep "" (g: "(memberOf=${ldapGroupDn g})") ldapCfg.accessGroups})";

  # "Remux + WEB" — TRaSH-Guides' own mainstream-documented, genuinely remux-primary
  # profile (cutoff: Remux-2160p/1080p). Deliberately not nixflix's radarrQuality-driven
  # SQP-1 default: SQP-1 was found to actually *exclude* Remux entirely
  # (Remux-2160p/1080p: allowed=false in its own trash-guides.info JSON) — the opposite
  # of the remux-primary strategy this repo actually wants (Jellyfin transcodes down for
  # 1080p clients, so one 4K/remux source serves every resolution). SQP has also since
  # been pulled from TRaSH's public docs entirely (Discord-gated as of 2025), where
  # Remux + WEB remains a normal, currently-documented profile.
  radarrRemuxProfile =
    if cfg.recyclarr.radarrQuality == "4K"
    then {
      trashId = "fd161a61e3ab826d3a22d53f935696dd";
      name = "Remux + WEB 2160p";
    }
    else {
      trashId = "9ca12ea80aa55ef916e3751f4b874151";
      name = "Remux + WEB 1080p";
    };

  lidarrQualityItems =
    map (quality: {
      inherit quality;
      items = [];
      allowed = builtins.elem quality.name ["FLAC" "FLAC 24bit"];
    }) [
      {
        id = 0;
        name = "Unknown";
      }
      {
        id = 32;
        name = "MP3-8";
      }
      {
        id = 31;
        name = "MP3-16";
      }
      {
        id = 30;
        name = "MP3-24";
      }
      {
        id = 29;
        name = "MP3-32";
      }
      {
        id = 28;
        name = "MP3-40";
      }
      {
        id = 27;
        name = "MP3-48";
      }
      {
        id = 26;
        name = "MP3-56";
      }
      {
        id = 25;
        name = "MP3-64";
      }
      {
        id = 24;
        name = "MP3-80";
      }
      {
        id = 23;
        name = "MP3-96";
      }
      {
        id = 33;
        name = "MP3-112";
      }
      {
        id = 22;
        name = "MP3-128";
      }
      {
        id = 19;
        name = "OGG Vorbis Q5";
      }
      {
        id = 5;
        name = "MP3-160";
      }
      {
        id = 1;
        name = "MP3-192";
      }
      {
        id = 18;
        name = "OGG Vorbis Q6";
      }
      {
        id = 9;
        name = "AAC-192";
      }
      {
        id = 20;
        name = "WMA";
      }
      {
        id = 34;
        name = "MP3-224";
      }
      {
        id = 17;
        name = "OGG Vorbis Q7";
      }
      {
        id = 8;
        name = "MP3-VBR-V2";
      }
      {
        id = 3;
        name = "MP3-256";
      }
      {
        id = 16;
        name = "OGG Vorbis Q8";
      }
      {
        id = 10;
        name = "AAC-256";
      }
      {
        id = 2;
        name = "MP3-VBR-V0";
      }
      {
        id = 12;
        name = "AAC-VBR";
      }
      {
        id = 4;
        name = "MP3-320";
      }
      {
        id = 15;
        name = "OGG Vorbis Q9";
      }
      {
        id = 11;
        name = "AAC-320";
      }
      {
        id = 14;
        name = "OGG Vorbis Q10";
      }
      {
        id = 6;
        name = "FLAC";
      }
      {
        id = 7;
        name = "ALAC";
      }
      {
        id = 35;
        name = "APE";
      }
      {
        id = 36;
        name = "WavPack";
      }
      {
        id = 21;
        name = "FLAC 24bit";
      }
      {
        id = 37;
        name = "ALAC 24bit";
      }
      {
        id = 13;
        name = "WAV";
      }
    ];
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    systemd = {
      services = {
        lidarr-custom-formats = {
          description = "Configure Lidarr custom formats via API";
          requires = ["lidarr-config.service"];
          after = ["lidarr-config.service"];
          before = ["lidarr-qualityprofiles.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            ExecStart = lidarrCustomFormatsScript;
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };

        lidarr-qualityprofiles = {
          requires = ["lidarr-custom-formats.service"];
          after = ["lidarr-custom-formats.service"];
        };
      };
    };

    nixflix = {
      enable = true;

      inherit (cfg) mediaDir downloadsDir stateDir;

      postgres = {
        enable = true;
      };

      jellyfin = lib.mkIf cfg.jellyfin.enable {
        enable = true;

        # Required — nixflix's own default (null) fails its own option type check
        # (jellyfin-api-key.service evaluates it unconditionally). Create with:
        # `uuidgen | base64`
        apiKey = {
          _secret = config.sops.secrets."arr/jellyfin/api-key".path;
        };

        encoding = {
          # `enableHardwareEncoding` alone only grants /dev/dri access (video/render
          # supplementary groups) — the actual accel backend is a separate field that
          # otherwise defaults to "none", silently leaving Jellyfin on pure CPU transcode.
          enableHardwareEncoding = cfg.jellyfin.hardwareAcceleration;
          hardwareAccelerationType = lib.mkIf cfg.jellyfin.hardwareAcceleration cfg.jellyfin.hardwareAccelerationType;
          vaapiDevice = lib.mkIf (cfg.jellyfin.hardwareAcceleration && cfg.jellyfin.hardwareAccelerationType == "vaapi") "/dev/dri/renderD128";

          # Library is largely UHD BluRay HDR/DV — needed to properly tone-map down to
          # SDR for non-HDR/DV-capable clients (e.g. 1080p laptops) instead of a naive
          # (washed out) conversion or an unnecessary software fallback.
          enableTonemapping = cfg.jellyfin.hardwareAcceleration;
        };

        libraries = {
          Movies = {
            enableRealtimeMonitor = true;
          };

          Shows = {
            enableRealtimeMonitor = true;
          };

          Music = {
            enableRealtimeMonitor = true;
          };
        };

        plugins = lib.mkIf ldapCfg.enable {
          "LDAP Authentication" = {
            enable = true;

            # Manifest name ("LDAP Authentication") differs from the name it reports via
            # Jellyfin's own /Plugins API ("LDAP-Auth") — confirmed live, same class of
            # mismatch nixflix's own docs call out for the SSO-Auth plugin.
            apiName = "LDAP-Auth";

            config = {
              LdapServer = ldapCfg.server;
              LdapPort = ldapCfg.port;
              UseSsl = false;
              UseStartTls = false;

              LdapBindUser = ldapCfg.bindDn;
              LdapBindPassword = {
                _secret = config.sops.secrets."arr/jellyfin/ldap-bind-password".path;
              };

              LdapBaseDn = ldapCfg.baseDn;
              LdapSearchFilter = ldapSearchFilter;
              LdapAdminFilter = "(memberOf=${ldapGroupDn ldapCfg.adminGroup})";

              LdapUidAttribute = "uid";
              LdapUsernameAttribute = "cn";
              CreateUsersFromLdap = true;
            };
          };

          "Kodi Sync Queue" = {
            enable = true;
          };
        };

        users = {
          admin = {
            mutable = false;

            policy = {
              isAdministrator = true;
            };

            password = {
              _secret = config.sops.secrets."arr/jellyfin/admin-password".path;
            };
          };
        };
      };

      usenetClients = {
        sabnzbd = lib.mkIf cfg.sabnzbd.enable {
          enable = true;
          # Keep Usenet on the normal host network; only slskd is VPN-confined.
          vpn.enable = false;

          settings = {
            misc = {
              api_key = {
                _secret = config.sops.secrets."arr/sabnzbd/api-key".path;
              };
              nzb_key = {
                _secret = config.sops.secrets."arr/sabnzbd/nzb-key".path;
              };

              # Deliberately no username/password: SABnzbd's own check_login() only
              # requires one when *both* are set, so leaving them unset drops its web
              # login entirely — the SABnzbd equivalent of Sonarr's documented
              # AuthenticationMethod=External trust model, now that Authentik's outpost
              # gates access before any request reaches SABnzbd. Otherwise it's a second,
              # redundant login on top of Authentik's. Doesn't affect Radarr/Sonarr/
              # Prowlarr's SABnzbd integration, which uses api_key, not this.

              web_dir = "Glitter";
              # Glitter's colour schemes are its actual CSS filenames (Light/Night/Auto),
              # not the UI's display label ("Dark") — SABnzbd silently resets anything
              # else to "" (Auto) on startup. Confirmed against the shipped stylesheets
              # at interfaces/Glitter/templates/static/stylesheets/colorschemes/.
              web_color = "Night";

              # Authentik's outpost proxies to SABnzbd via internal_host (see infra-tofu's
              # proxy-apps.sops.json) and may send that hostname as the Host header rather
              # than sabnzbd.${domain} — SABnzbd's Host-header check (check_hostname,
              # DNS-rebinding protection) would otherwise reject it. Needs both: the public
              # app domain and the internal tailnet hostname the outpost connects through.
              host_whitelist = "sabnzbd.${domain},heartbeat.dns.headscale.${domain}";

              # The actual "External internet access denied" error hit in practice comes
              # from a *different*, earlier check (check_access/inet_exposure), which
              # only ever looks at the direct TCP peer's IP — the outpost's own tailnet
              # IP (accesscontrolsystem, 100.64.0.0/10), not the original browser's IP.
              # SABnzbd's default local_ranges is RFC1918 only, which doesn't cover
              # Tailscale's CGNAT range, so the outpost's connection reads as "external"
              # even though nothing is actually exposed past the tailnet.
              local_ranges = "100.64.0.0/10";

              # With local_ranges fixed, the direct peer (the outpost, 100.64.0.1) passes —
              # but verify_xff_header then separately re-checks every hop in
              # X-Forwarded-For against local_ranges too, including the original client's
              # real public IP forwarded through Caddy. That's a real, non-local address by
              # design here (SSO-gated access from outside the LAN is the whole point), so
              # this spoofing check — meant for plain reverse-proxy setups where every
              # legitimate caller really is LAN-local — has to be off. Authentik's outpost
              # is what actually gates access; this would just reject genuine users.
              verify_xff_header = false;
            };

            servers = cfg.usenetProviders;
          };
        };
      };

      prowlarr = lib.mkIf cfg.prowlarr.enable {
        enable = true;

        config = {
          apiKey = {
            _secret = config.sops.secrets."arr/prowlarr/api-key".path;
          };

          hostConfig = {
            # Authentik's outpost (accesscontrolsystem) connects to Prowlarr's backend
            # directly over the tailnet via internal_host — 127.0.0.1 refuses that
            # connection entirely (confirmed with Sonarr/Radarr: Bad Gateway).
            bindAddress = "0.0.0.0";
            # See the matching comment on sonarr's hostConfig above.
            username = "prowlarr";
            password = "unused-authenticationMethod-is-external";

            # Trust Authentik's outpost — matches Sonarr/Radarr's hostConfig above.
            authenticationMethod = "external";
            applicationUrl = "https://prowlarr.${domain}";
          };

          inherit (cfg) indexers;
        };
      };

      sonarr = lib.mkIf cfg.sonarr.enable {
        enable = true;

        config = {
          apiKey = {
            _secret = config.sops.secrets."arr/sonarr/api-key".path;
          };

          hostConfig = {
            # Authentik's outpost (accesscontrolsystem) connects to Sonarr's backend
            # directly over the tailnet via internal_host — 127.0.0.1 would refuse that
            # connection entirely (confirmed live: Bad Gateway, connection refused).
            # Matches SABnzbd's equivalent tailscale0 firewall scoping below.
            bindAddress = "0.0.0.0";
            # Not a real secret — authenticationMethod=external below means Sonarr never
            # actually checks this. But nixflix gates its *entire* sonarr-config.service
            # (which applies every hostConfig field, not just auth) behind
            # `password != null`, and sonarr-rootfolders/mediamanagement/downloadclients
            # all Requires= that unit — leaving it null broke all of those too, not just
            # auth. A placeholder satisfies the gate without needing a real secret.
            username = "sonarr";
            password = "unused-authenticationMethod-is-external";

            # Trust Authentik's outpost, which now sits in front via Caddy (see the
            # sonarr.${domain} vhost below) — matches Authentik's own documented Sonarr
            # integration guide exactly (config.xml AuthenticationMethod=External).
            # authenticationRequired stays "enabled": with authenticationMethod=external
            # Sonarr never shows its own login regardless, and this keeps the setting
            # correct/inert rather than silently trusting all local addresses too.
            authenticationMethod = "external";
            applicationUrl = "https://sonarr.${domain}";
          };
        };
      };

      radarr = lib.mkIf cfg.radarr.enable {
        enable = true;

        config = {
          apiKey = {
            _secret = config.sops.secrets."arr/radarr/api-key".path;
          };

          hostConfig = {
            # See the matching comment on sonarr's hostConfig above.
            bindAddress = "0.0.0.0";
            # See the matching comment on sonarr's hostConfig above.
            username = "radarr";
            password = "unused-authenticationMethod-is-external";

            # See the matching comment on sonarr's hostConfig above.
            authenticationMethod = "external";
            applicationUrl = "https://radarr.${domain}";
          };
        };
      };

      lidarr = lib.mkIf cfg.lidarr.enable {
        enable = true;

        mediaDirs = ["${cfg.mediaDir}/music"];

        config = {
          apiKey = {
            _secret = config.sops.secrets."arr/lidarr/api-key".path;
          };

          hostConfig = {
            bindAddress = "0.0.0.0";
            username = "lidarr";
            password = "unused-authenticationMethod-is-external";
            authenticationMethod = "external";
            applicationUrl = "https://lidarr.${domain}";
          };

          qualityProfiles = [
            {
              name = "Any";
              upgradeAllowed = true;
              cutoff = 21;
              items = lidarrQualityItems;
              minFormatScore = 0;
              formatItems = [
                {
                  format = 5;
                  name = "Vinyl";
                  score = -1000;
                }
                {
                  format = 4;
                  name = "Lossless";
                  score = 0;
                }
                {
                  format = 3;
                  name = "WEB";
                  score = 0;
                }
                {
                  format = 2;
                  name = "CD";
                  score = 0;
                }
                {
                  format = 1;
                  name = "Preferred Groups";
                  score = 0;
                }
              ];
            }
          ];

          metadataProfiles = [
            {
              name = "Standard";

              primaryAlbumTypes = {
                enableAlbum = true;
              };

              secondaryAlbumTypes = {
                enableStudio = true;
              };

              releaseStatuses = {
                enableOfficial = true;
              };
            }
          ];

          mediaManagement = {
            rescanAfterRefresh = "afterManual";
          };
        };
      };

      navidrome = lib.mkIf cfg.navidrome.enable {
        enable = true;
        vpn.enable = false;

        settings = {
          MusicFolder = "${cfg.mediaDir}/music";
          "Scanner.PurgeMissing" = "full";
        };
      };

      recyclarr = lib.mkIf cfg.recyclarr.enable {
        enable = true;

        # sonarrQuality still drives nixflix's own WEB-Alternative default (no
        # radarrQuality here — Radarr's profile is fully hand-specified below, since it
        # needs to be the actual Remux + WEB profile rather than nixflix's SQP-1 default).
        inherit (cfg.recyclarr) sonarrQuality;

        config = {
          radarr = {
            radarr = lib.mkIf cfg.radarr.enable {
              quality_definition = {
                type = "movie";
              };

              quality_profiles = [
                {
                  trash_id = radarrRemuxProfile.trashId;
                  reset_unmatched_scores.enabled = true;
                }
                {
                  trash_id = "9ca12ea80aa55ef916e3751f4b874151"; # Remux + WEB 1080p
                  reset_unmatched_scores.enabled = true;
                }
              ];

              # All audio formats score at TRaSH's own defaults, no TrueHD penalty —
              # confirmed Apple TV + Infuse plays all of these back fine (Infuse decodes
              # HD audio to LPCM in software rather than relying on passthrough).
              custom_formats = [
                {
                  trash_ids = [
                    "0d7824bb924701997f874e7ff7d4844a" # TrueHD ATMOS
                    "9d00418ba386a083fbf4d58235fc37ef" # DTS X
                    "b6fbafa7942952a13e17e2b1152b539a" # ATMOS (undefined)
                    "4232a509ce60c4e208d13825b7c06264" # DD+ ATMOS
                    "1808e4b9cee74e064dfae3f1db99dbfe" # TrueHD
                    "c429417a57ea8c41d57e6990a8b0033f" # DTS-HD MA
                    "851bd64e04c9374c51102be3dd9ae4cc" # FLAC
                    "30f70576671ca933adbdcfc736a69718" # PCM
                    "cfa5fbd8f02a86fc55d8d223d06a5e1f" # DTS-HD HRA
                    "63487786a8b01b7f20dd2bc90dd4a477" # DD+
                    "c1a25cd67b5d2e08287c957b1eb903ec" # DTS-ES
                    "5964f2a8b3be407d083498e4459d05d0" # DTS
                    "a50b8a0c62274a7c38b09a9619ba9d86" # AAC
                    "dbe00161b08a25ac6154c55f95e6318d" # DD
                  ];
                  assign_scores_to = [
                    {
                      trash_id = "fd161a61e3ab826d3a22d53f935696dd";
                    }
                    {
                      trash_id = "9ca12ea80aa55ef916e3751f4b874151";
                    }
                  ];
                }
                {
                  trash_ids = [
                    "923b6abef9b17f937fab56cfcf89e1f1" # DV (w/o HDR fallback)
                    "b337d6812e06c200ec9a2d3cfa9d20a7" # DV Boost
                    "caa37d0df9c348912df1fb1d88f9273a" # HDR10+ Boost
                    "493b6d1dbec3c3364c59d7607f7e3405" # HDR
                  ];
                  assign_scores_to = [
                    {
                      trash_id = "fd161a61e3ab826d3a22d53f935696dd";
                    }
                    {
                      trash_id = "9ca12ea80aa55ef916e3751f4b874151";
                    }
                  ];
                }
              ];
            };
          };

          sonarr = {
            sonarr = lib.mkIf cfg.sonarr.enable {
              quality_profiles = [
                {
                  trash_id = "dfa5eaae7894077ad6449169b6eb03e0"; # WEB-2160p (Alternative)
                  reset_unmatched_scores.enabled = true;
                }
                {
                  trash_id = "9d142234e45d6143785ac55f5a9e8dc9"; # WEB-1080p (Alternative)
                  reset_unmatched_scores.enabled = true;
                }
              ];

              custom_formats = [
                {
                  trash_ids = [
                    "9b27ab6498ec0f31a3353992e19434ca" # DV (w/o HDR fallback)
                    "7c3a61a9c6cb04f52f1544be6d44a026" # DV Boost
                    "0c4b99df9206d2cfac3c05ab897dd62a" # HDR10+ Boost
                    "505d871304820ba7106b693be6fe4a9e" # HDR
                  ];
                  assign_scores_to = [
                    {
                      trash_id = "dfa5eaae7894077ad6449169b6eb03e0";
                    }
                    {
                      trash_id = "9d142234e45d6143785ac55f5a9e8dc9";
                    }
                  ];
                }
                {
                  trash_ids = [
                    "496f355514737f7d83bf7aa4d24f8169" # TrueHD Atmos
                    "2f22d89048b01681dde8afe203bf2e95" # DTS X
                    "417804f7f2c4308c1f4c5d380d4c4475" # ATMOS (undefined)
                    "1af239278386be2919e1bcee0bde047e" # DD+ ATMOS
                    "3cafb66171b47f226146a0770576870f" # TrueHD
                    "dcf3ec6938fa32445f590a4da84256cd" # DTS-HD MA
                    "a570d4a0e56a2874b64e5bfa55202a1b" # FLAC
                    "e7c2fcae07cbada050a0af3357491d7b" # PCM
                    "8e109e50e0a0b83a5098b056e13bf6db" # DTS-HD HRA
                    "185f1dd7264c4562b9022d963ac37424" # DD+
                    "f9f847ac70a0af62ea4a08280b859636" # DTS-ES
                    "1c1a4c5e823891c75bc50380a6866f73" # DTS
                    "240770601cc226190c367ef59aba7463" # AAC
                    "c2998bd0d90ed5621d8df281e839436e" # DD
                  ];
                  assign_scores_to = [
                    {
                      trash_id = "dfa5eaae7894077ad6449169b6eb03e0";
                    }
                    {
                      trash_id = "9d142234e45d6143785ac55f5a9e8dc9";
                    }
                  ];
                }
              ];
            };
          };
        };
      };

      seerr = lib.mkIf cfg.seerr.enable {
        enable = true;

        apiKey = {
          _secret = config.sops.secrets."arr/seerr/api-key".path;
        };

        settings = {
          users = {
            # LDAP (via Jellyfin) is the only login path — no separate local Seerr accounts.
            localLogin = false;
          };
        };

        jellyfin = {
          hostname = "jellyfin.${domain}";
          port = 443;
          useSsl = true;
        };

        # nixflix's per-app default instance (hostname/port/apiKey/directory/etc.) lives
        # entirely in its option-level `default`, which is discarded the moment any
        # module defines part of the same attrset key — NixOS falls back to each
        # submodule field's own (unwired) default instead of merging with nixflix's
        # auto-derivation. So this has to fully replicate that default, not just add
        # activeProfileName on top of it (confirmed the hard way: a partial override
        # silently nulled out apiKey and broke eval).
        radarr = lib.mkIf cfg.radarr.enable {
          Radarr = {
            hostname = config.nixflix.radarr.connectionAddress;
            port = config.nixflix.radarr.config.hostConfig.port or 7878;
            inherit (config.nixflix.radarr.config) apiKey;
            baseUrl = config.nixflix.radarr.config.hostConfig.urlBase;
            activeDirectory = builtins.head (config.nixflix.radarr.mediaDirs or ["/data/media/movies"]);
            isDefault = true;
            # nixflix's own default derives this from nixflix.reverseProxy.enable, which
            # is false here — we run our own Caddy, not nixflix's built-in reverse proxy —
            # so that default always evaluates to "", leaving Seerr's "open in Radarr"
            # links pointing at http://127.0.0.1:<port>, unreachable from a browser.
            externalUrl = "https://radarr.${domain}${config.nixflix.radarr.config.hostConfig.urlBase}";

            activeProfileName = radarrRemuxProfile.name;
          };
        };

        sonarr = lib.mkIf cfg.sonarr.enable {
          Sonarr = {
            hostname = config.nixflix.sonarr.connectionAddress;
            port = config.nixflix.sonarr.config.hostConfig.port or 8989;
            inherit (config.nixflix.sonarr.config) apiKey;
            baseUrl = config.nixflix.sonarr.config.hostConfig.urlBase;
            activeDirectory = builtins.head (config.nixflix.sonarr.mediaDirs or ["/data/media/tv"]);
            activeAnimeDirectory = builtins.head (config.nixflix.sonarr.mediaDirs or ["/data/media/tv"]);
            seriesType = "standard";
            animeSeriesType = "standard";
            isDefault = true;
            # See the matching comment on radarr's externalUrl above.
            externalUrl = "https://sonarr.${domain}${config.nixflix.sonarr.config.hostConfig.urlBase}";

            activeProfileName =
              if cfg.recyclarr.sonarrQuality == "4K"
              then "WEB-2160p (Alternative)"
              else "WEB-1080p (Alternative)";
          };
        };
      };

      slskd = lib.mkIf cfg.slskd.enable {
        enable = true;
        openFirewall = true;
        username = cfg.slskd.username;
        password = cfg.slskd.password;
        apiKey = cfg.slskd.apiKey;
        downloadsDir = cfg.slskd.downloadsDir;
        vpn.enable = cfg.slskd.vpn.enable;
        settings = {
          # Authentik protects the public vhost. slskd's own JWT login cannot
          # consume Authentik's proxy session, so leaving it enabled makes the
          # UI load but causes every API request to return 401.
          web = {
            authentication = {
              disabled = true;
            };
          };
          shares.directories = cfg.slskd.shareDirs;
          soulseek = {
            username = cfg.slskd.soulseekUsername;
            password = cfg.slskd.soulseekPassword;
          };
        };
      };
    };

    systemd = {
      services = {
        lidarr-naming = lib.mkIf cfg.lidarr.enable {
          description = "Configure Lidarr naming convention";
          wantedBy = ["multi-user.target"];
          after = ["lidarr.service"];
          requires = ["lidarr.service"];
          path = [pkgs.curl pkgs.coreutils];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lidarrNamingScript;
          };
        };

        slskd = {
          serviceConfig = {
            UMask = "0007";
          };
        };
      };
    };

    # Authentik's embedded outpost (running on accesscontrolsystem, reached over the
    # tailnet) proxies each SSO-fronted app directly via its Proxy Provider's
    # internal_host — it needs to reach this machine's backends itself, not go through
    # Caddy. Scoped to the tailscale0 interface, matching the LDAP outpost's port-3389
    # rule on accesscontrolsystem (machines/accesscontrolsystem/_config.nix).
    networking.firewall = lib.mkIf (cfg.sabnzbd.enable || cfg.sonarr.enable || cfg.radarr.enable || cfg.lidarr.enable || cfg.prowlarr.enable || cfg.navidrome.enable || cfg.slskd.enable) {
      interfaces = {
        tailscale0 = {
          allowedTCPPorts =
            lib.optional cfg.sabnzbd.enable config.nixflix.usenetClients.sabnzbd.settings.misc.port
            ++ lib.optional cfg.sonarr.enable config.nixflix.sonarr.config.hostConfig.port
            ++ lib.optional cfg.radarr.enable config.nixflix.radarr.config.hostConfig.port
            ++ lib.optional cfg.lidarr.enable config.nixflix.lidarr.config.hostConfig.port
            ++ lib.optional cfg.prowlarr.enable config.nixflix.prowlarr.config.hostConfig.port
            ++ lib.optional cfg.navidrome.enable config.nixflix.navidrome.settings.Port
            ++ lib.optional cfg.slskd.enable config.nixflix.slskd.settings.web.port;
        };
      };
    };

    assertions = [
      {
        assertion = !cfg.navidrome.enable || cfg.lidarr.enable;
        message = "homelab.services.arr.navidrome.enable requires homelab.services.arr.lidarr.enable so both services share the music directory.";
      }
      {
        assertion = !(cfg.jellyfin.enable && cfg.jellyfin.hardwareAcceleration) || config.homelab.hardware.graphics.enable;
        message = ''
          homelab.services.arr.jellyfin.hardwareAcceleration is on but homelab.hardware.graphics.enable
          is not set on this machine. The GPU driver packages required by the selected backend
          won't be installed, and every hardware transcode will fail. Set
          homelab.hardware.graphics = { enable = true; driver = "intel"; }; in this machine's
          _config.nix (a hardware fact about the machine, not something this service should assert).
        '';
      }
    ];

    homelab = {
      zfs = {
        datasets = {
          arr = {
            enable = true;
            dataset = "fpool/fast/services/arr";
            mountpoint = cfg.stateDir;

            requiredBy =
              lib.optional cfg.jellyfin.enable "jellyfin.service"
              ++ lib.optional cfg.sonarr.enable "sonarr.service"
              ++ lib.optional cfg.radarr.enable "radarr.service"
              ++ lib.optional cfg.prowlarr.enable "prowlarr.service"
              ++ lib.optional cfg.sabnzbd.enable "sabnzbd.service"
              ++ lib.optional cfg.seerr.enable "seerr.service"
              ++ lib.optional cfg.lidarr.enable "lidarr.service"
              ++ lib.optional cfg.navidrome.enable "navidrome.service"
              ++ lib.optional cfg.slskd.enable "slskd.service";

            restic = {
              enable = true;
            };
          };
        };
      };

      services = {
        backup = {
          serviceUnits =
            lib.optional cfg.jellyfin.enable "jellyfin.service"
            ++ lib.optional cfg.sonarr.enable "sonarr.service"
            ++ lib.optional cfg.radarr.enable "radarr.service"
            ++ lib.optional cfg.prowlarr.enable "prowlarr.service"
            ++ lib.optional cfg.sabnzbd.enable "sabnzbd.service"
            ++ lib.optional cfg.seerr.enable "seerr.service"
            ++ lib.optional cfg.lidarr.enable "lidarr.service"
            ++ lib.optional cfg.navidrome.enable "navidrome.service";
        };
      };
    };

    services = {
      restic = lib.mkIf resticEnabled {
        backups = {
          backup = {
            exclude = [
              "/mnt/nightly_backup/arr/jellyfin/cache"
              "/mnt/nightly_backup/arr/jellyfin/data/transcodes"
              "/mnt/nightly_backup/arr/sabnzbd/admin/logs"
            ];
          };
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = lib.mkMerge [
          (lib.mkIf cfg.jellyfin.enable {
            "jellyfin.${domain}" = {
              useACMEHost = domain;
              extraConfig = ''
                reverse_proxy http://127.0.0.1:${toString config.nixflix.jellyfin.network.internalHttpPort}
              '';
            };
          })
          (lib.mkIf cfg.sonarr.enable {
            "sonarr.${domain}" = {
              useACMEHost = domain;
              # SSO via Authentik's embedded outpost — see the matching comment on
              # sabnzbd's vhost below for why this is full Proxy mode, not forward_single.
              extraConfig = ''
                reverse_proxy https://auth.${domain} {
                  header_up Host {http.request.host}
                }
              '';
            };
          })
          (lib.mkIf cfg.radarr.enable {
            "radarr.${domain}" = {
              useACMEHost = domain;
              # SSO via Authentik's embedded outpost — see the matching comment on
              # sabnzbd's vhost below for why this is full Proxy mode, not forward_single.
              extraConfig = ''
                reverse_proxy https://auth.${domain} {
                  header_up Host {http.request.host}
                }
              '';
            };
          })
          (lib.mkIf cfg.lidarr.enable {
            "lidarr.${domain}" = {
              useACMEHost = domain;
              extraConfig = ''
                reverse_proxy https://auth.${domain} {
                  header_up Host {http.request.host}
                }
              '';
            };
          })
          (lib.mkIf cfg.prowlarr.enable {
            "prowlarr.${domain}" = {
              useACMEHost = domain;
              # SSO via Authentik's embedded outpost — see the matching comment on
              # sabnzbd's vhost below for why this is full Proxy mode, not forward_single.
              extraConfig = ''
                reverse_proxy https://auth.${domain} {
                  header_up Host {http.request.host}
                }
              '';
            };
          })
          (lib.mkIf cfg.sabnzbd.enable {
            "sabnzbd.${domain}" = {
              useACMEHost = domain;
              # SSO via Authentik's embedded outpost (Proxy Provider, mode = proxy — see
              # infra-tofu's modules/authentik/proxy.tf). SABnzbd has no OIDC/SAML of its
              # own, unlike Jellyfin's LDAP plugin, so this is the only way to put SSO in
              # front of it. Deliberately full Proxy mode, not forward_single/forward_domain:
              # a forward_single split (Caddy asking the outpost "is this OK?" via a side
              # channel, then separately proxying to the backend itself) was tried first and
              # its auth-check endpoint returned 200 for fully anonymous requests — an
              # unexplained bypass. In Proxy mode the outpost IS the reverse proxy (it
              # forwards to the provider's internal_host itself once authenticated), so
              # there's no separate unauthenticated path to the backend for Caddy to
              # accidentally take.
              #
              # header_up Host is required: Authentik's outpost matches the incoming
              # request against a provider by Host header, which must equal the app's own
              # external_host (sabnzbd.${domain}), not auth.${domain}.
              extraConfig = ''
                reverse_proxy https://auth.${domain} {
                  header_up Host {http.request.host}
                }
              '';
            };
          })
          (lib.mkIf cfg.seerr.enable {
            "seerr.${domain}" = {
              useACMEHost = domain;
              extraConfig = ''
                reverse_proxy http://127.0.0.1:${toString config.nixflix.seerr.port}
              '';
            };
          })
          (lib.mkIf cfg.navidrome.enable {
            "navidrome.${domain}" = {
              useACMEHost = domain;
              extraConfig = ''
                reverse_proxy http://127.0.0.1:${toString config.nixflix.navidrome.settings.Port}
              '';
            };
          })
          (lib.mkIf cfg.slskd.enable {
            "slskd.${domain}" = {
              useACMEHost = domain;
              extraConfig = ''
                reverse_proxy https://auth.${domain} {
                  header_up Host {http.request.host}
                }
              '';
            };
          })
        ];
      };
    };

    # Prowlarr 2.6 rejects the host-config payload from nixflix because it does
    # not yet include the new required AllowedHosts field. Keep the rest of
    # nixflix's declarative payload intact and add the explicit host allow-list
    # until the upstream module grows support for it.
    systemd.services = {
      # Seerr rejects an empty externalHostname on its current API (HTTP 503
      # INVALID_URL). Keep the generated service dependencies and credentials,
      # but submit a valid external Jellyfin URL explicitly.
      seerr-jellyfin = lib.mkIf cfg.seerr.enable {
        script = ''
          set -euo pipefail

          BASE_URL="http://127.0.0.1:${toString config.nixflix.seerr.port}"
          API_KEY_HEADER="/run/seerr/api-key-header"
          if [ ! -r "$API_KEY_HEADER" ]; then
            echo "Seerr API key header is missing" >&2
            exit 1
          fi

          ${pkgs.curl}/bin/curl -fsS -X POST \
            --header @"$API_KEY_HEADER" \
            -H "Content-Type: application/json" \
          -d '${builtins.toJSON {
            ip = config.nixflix.seerr.jellyfin.hostname;
            port = config.nixflix.seerr.jellyfin.port;
            useSsl = config.nixflix.seerr.jellyfin.useSsl;
            urlBase = "";
            externalHostname = "https://${config.nixflix.seerr.jellyfin.hostname}";
          }}' \
            "$BASE_URL/api/v1/settings/jellyfin" >/dev/null
        '';
      };

      # nixflix's generated readiness hook probes bindAddress (0.0.0.0), which
      # Prowlarr's host filter rejects. Probe the loopback address instead.
      prowlarr = lib.mkIf cfg.prowlarr.enable {
        serviceConfig.ExecStartPost = lib.mkForce (pkgs.writeShellScript "prowlarr-wait-for-api-local" ''
          set -eu
          API_KEY=$(cat /run/credentials/prowlarr.service/apiKey)
          for i in $(seq 1 90); do
            if ${pkgs.curl}/bin/curl -fsS -H "X-Api-Key: $API_KEY" \
              http://127.0.0.1:${toString config.nixflix.prowlarr.config.hostConfig.port}/api/${config.nixflix.prowlarr.config.apiVersion}/system/status \
              >/dev/null 2>&1; then
              exit 0
            fi
            sleep 1
          done
          echo "Prowlarr API not available after 90 seconds" >&2
          exit 1
        '');
      };

      prowlarr-config = lib.mkIf cfg.prowlarr.enable {
        serviceConfig = {
          ExecStartPre = lib.mkForce [];
          ExecStartPost = lib.mkForce [];
        };

        script = lib.mkForce ''
          set -eu

          BASE_URL="http://127.0.0.1:${toString config.nixflix.prowlarr.config.hostConfig.port}${config.nixflix.prowlarr.config.hostConfig.urlBase}/api/${config.nixflix.prowlarr.config.apiVersion}"
          API_KEY=$(cat ${lib.escapeShellArg config.sops.secrets."arr/prowlarr/api-key".path})

          echo "Fetching current host configuration..."
          HOST_CONFIG=$(${pkgs.curl}/bin/curl -fsS -H "X-Api-Key: $API_KEY" "$BASE_URL/config/host")
          CONFIG_ID=$(echo "$HOST_CONFIG" | ${pkgs.jq}/bin/jq -r '.id')

          echo "Building configuration..."
          NEW_CONFIG=$(echo "$HOST_CONFIG" | ${pkgs.jq}/bin/jq \
            --arg apiKey "$API_KEY" \
            --arg bindAddress ${lib.escapeShellArg config.nixflix.prowlarr.config.hostConfig.bindAddress} \
            --arg authenticationMethod ${lib.escapeShellArg config.nixflix.prowlarr.config.hostConfig.authenticationMethod} \
            --arg authenticationRequired ${lib.escapeShellArg config.nixflix.prowlarr.config.hostConfig.authenticationRequired} \
            --arg applicationUrl ${lib.escapeShellArg config.nixflix.prowlarr.config.hostConfig.applicationUrl} \
            --arg allowedHosts ${lib.escapeShellArg "prowlarr.${domain},heartbeat.dns.headscale.${domain},localhost,127.0.0.1,0.0.0.0"} \
            '. + {
              bindAddress: $bindAddress,
              port: ${toString config.nixflix.prowlarr.config.hostConfig.port},
              authenticationMethod: $authenticationMethod,
              authenticationRequired: $authenticationRequired,
              username: "prowlarr",
              password: "unused-authenticationMethod-is-external",
              passwordConfirmation: "unused-authenticationMethod-is-external",
              apiKey: $apiKey,
              applicationUrl: $applicationUrl,
              allowedHosts: $allowedHosts
            }')

          echo "Updating Prowlarr configuration via API..."
          ${pkgs.curl}/bin/curl -fsS -X PUT \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            --data "$NEW_CONFIG" \
            "$BASE_URL/config/host/$CONFIG_ID" > /dev/null

          # The API applies this host configuration live. An explicit restart here
          # deadlocks with the wantedBy config unit and times out during activation.
          echo "Configuration updated successfully"
        '';
      };
    };
  };
}
