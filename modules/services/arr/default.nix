# Arr media stack — wraps the nixflix flake input (declarative Servarr provisioning via
# each app's REST API) behind this repo's normal homelab.services.arr.* convention.
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.arr;
  caddyEnabled = config.homelab.services.caddy.enable;
  resticEnabled = config.homelab.services.restic.enable;
  domain = config.networking.domain;
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
