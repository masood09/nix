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
              username = {
                _secret = config.sops.secrets."arr/sabnzbd/username".path;
              };
              password = {
                _secret = config.sops.secrets."arr/sabnzbd/password".path;
              };
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
            bindAddress = "127.0.0.1";
            password = {
              _secret = config.sops.secrets."arr/sonarr/password".path;
            };
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
            bindAddress = "127.0.0.1";
            password = {
              _secret = config.sops.secrets."arr/radarr/password".path;
            };
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
            externalUrl =
              if config.nixflix.reverseProxy.enable
              then "${config.nixflix.seerr.externalUrlScheme}://${config.nixflix.radarr.subdomain}.${config.nixflix.reverseProxy.domain}${config.nixflix.radarr.config.hostConfig.urlBase}"
              else "";

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
            externalUrl =
              if config.nixflix.reverseProxy.enable
              then "${config.nixflix.seerr.externalUrlScheme}://${config.nixflix.sonarr.subdomain}.${config.nixflix.reverseProxy.domain}${config.nixflix.sonarr.config.hostConfig.urlBase}"
              else "";

            activeProfileName =
              if cfg.recyclarr.sonarrQuality == "4K"
              then "WEB-2160p (Alternative)"
              else "WEB-1080p (Alternative)";
          };
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
              extraConfig = ''
                reverse_proxy http://127.0.0.1:${toString config.nixflix.sonarr.config.hostConfig.port}
              '';
            };
          })
          (lib.mkIf cfg.radarr.enable {
            "radarr.${domain}" = {
              useACMEHost = domain;
              extraConfig = ''
                reverse_proxy http://127.0.0.1:${toString config.nixflix.radarr.config.hostConfig.port}
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
              extraConfig = ''
                reverse_proxy http://127.0.0.1:8080
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
