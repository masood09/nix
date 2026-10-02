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
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
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

        plugins = lib.mkIf ldapCfg.enable {
          "LDAP Authentication" = {
            package = inputs.nixflix.lib.jellyfinPlugins.fromRepo {
              version = "23.0.0.0";
              hash = "sha256-yuOAJTj+QKj6bxlJ+irDE2BjxH1ZbsgAri7fauDMOBM=";
            };

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
    };

    # Authentik's embedded outpost (running on accesscontrolsystem, reached over the
    # tailnet) proxies each SSO-fronted app directly via its Proxy Provider's
    # internal_host — it needs to reach this machine's backends itself, not go through
    # Caddy. Scoped to the tailscale0 interface, matching the LDAP outpost's port-3389
    # rule on accesscontrolsystem (machines/accesscontrolsystem/_config.nix).
    networking.firewall = lib.mkIf (cfg.sabnzbd.enable || cfg.sonarr.enable || cfg.radarr.enable || cfg.prowlarr.enable) {
      interfaces = {
        tailscale0 = {
          allowedTCPPorts =
            lib.optional cfg.sabnzbd.enable config.nixflix.usenetClients.sabnzbd.settings.misc.port
            ++ lib.optional cfg.sonarr.enable config.nixflix.sonarr.config.hostConfig.port
            ++ lib.optional cfg.radarr.enable config.nixflix.radarr.config.hostConfig.port
            ++ lib.optional cfg.prowlarr.enable config.nixflix.prowlarr.config.hostConfig.port;
        };
      };
    };

    assertions = [
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
              ++ lib.optional cfg.seerr.enable "seerr.service";

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
            ++ lib.optional cfg.seerr.enable "seerr.service";
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
        ];
      };
    };

    # Prowlarr 2.6 rejects the host-config payload from nixflix because it does
    # not yet include the new required AllowedHosts field. Keep the rest of
    # nixflix's declarative payload intact and add the explicit host allow-list
    # until the upstream module grows support for it.
    systemd.services = {
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
