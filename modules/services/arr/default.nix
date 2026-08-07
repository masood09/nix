# Arr media stack — wraps the nixflix flake input (declarative Servarr provisioning via
# each app's REST API) behind this repo's normal homelab.services.arr.* convention.
{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.homelab.services.arr;
  caddyEnabled = config.homelab.services.caddy.enable;
  resticEnabled = config.homelab.services.restic.enable;
  domain = config.networking.domain;

  ldapCfg = cfg.jellyfin.ldap;
  ldapGroupDn = group: "cn=${group},ou=groups,${ldapCfg.baseDn}";
  ldapSearchFilter = "(|${lib.concatMapStringsSep "" (g: "(memberOf=${ldapGroupDn g})") ldapCfg.accessGroups})";
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
          hardwareAccelerationType = lib.mkIf cfg.jellyfin.hardwareAcceleration "vaapi";
          vaapiDevice = lib.mkIf cfg.jellyfin.hardwareAcceleration "/dev/dri/renderD128";

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
            bindAddress = "127.0.0.1";
            password = {
              _secret = config.sops.secrets."arr/prowlarr/password".path;
            };
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
            password = {
              _secret = config.sops.secrets."arr/sonarr/password".path;
            };

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
            password = {
              _secret = config.sops.secrets."arr/radarr/password".path;
            };

            # See the matching comment on sonarr's hostConfig above.
            authenticationMethod = "external";
            applicationUrl = "https://radarr.${domain}";
          };
        };
      };

      recyclarr = lib.mkIf cfg.recyclarr.enable {
        enable = true;

        # Matches a 4K/remux-primary download strategy (Jellyfin transcodes down for
        # 1080p clients). See the Apple TV/Infuse TrueHD caveat noted in the plan doc —
        # deprioritize/allow transcode-fallback for TrueHD custom formats even though DV
        # and Atmos passthrough are fine there.
        inherit (cfg.recyclarr) radarrQuality sonarrQuality;
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

            activeProfileName =
              if cfg.recyclarr.radarrQuality == "4K"
              then "[SQP] SQP-1 (2160p)"
              else "[SQP] SQP-1 (1080p)";
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
    networking.firewall = lib.mkIf (cfg.sabnzbd.enable || cfg.sonarr.enable || cfg.radarr.enable) {
      interfaces = {
        tailscale0 = {
          allowedTCPPorts =
            lib.optional cfg.sabnzbd.enable config.nixflix.usenetClients.sabnzbd.settings.misc.port
            ++ lib.optional cfg.sonarr.enable config.nixflix.sonarr.config.hostConfig.port
            ++ lib.optional cfg.radarr.enable config.nixflix.radarr.config.hostConfig.port;
        };
      };
    };

    assertions = [
      {
        assertion = !(cfg.jellyfin.enable && cfg.jellyfin.hardwareAcceleration) || config.homelab.hardware.graphics.enable;
        message = ''
          homelab.services.arr.jellyfin.hardwareAcceleration is on but homelab.hardware.graphics.enable
          is not set on this machine. The VAAPI/OpenCL driver packages that back /dev/dri/renderD128
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
              extraConfig = ''
                reverse_proxy http://127.0.0.1:${toString config.nixflix.prowlarr.config.hostConfig.port}
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
  };
}
