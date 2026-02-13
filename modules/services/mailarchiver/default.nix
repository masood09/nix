{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.mailarchiver;
  podmanEnabled = homelabCfg.services.podman.enable;
  caddyEnabled = config.services.caddy.enable;
  postgresqlEnabled = config.services.postgresql.enable;
  postgresqlBackupEnabled = config.services.postgresqlBackup.enable;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf (cfg.enable && podmanEnabled) {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.mailarchiver = lib.mkIf cfg.zfs.enable {
      inherit (cfg.zfs) dataset properties;

      enable = true;
      mountpoint = cfg.dataDir;

      requiredBy = [
        "podman-mailarchiver.service"
      ];

      restic = {
        enable = true;
      };
    };

    virtualisation.oci-containers.containers.mailarchiver = {
      # renovate: datasource=docker depName=docker.io/s1t5/mailarchiver
      image = "docker.io/s1t5/mailarchiver:2602.1";
      autoStart = true;

      ports = [
        "${cfg.listenAddress}:${toString cfg.listenPort}:5000"
      ];

      environment = {
        TimeZone__DisplayTimeZoneId = config.time.timeZone;
        OAuth__Enabled = cfg.oauth.enable;
        OAuth__Authority = cfg.oauth.issuerURL;
        OAuth__ClientId = cfg.oauth.clientID;
        OAuth__ClientScopes__0 = "openid";
        OAuth__ClientScopes__1 = "profile";
        OAuth__ClientScopes__2 = "email";
        OAuth__DisablePasswordLogin = cfg.oauth.disablePasswordLogin;
        OAuth__AutoRedirect = cfg.oauth.autoRedirect;
      };

      environmentFiles = [
        config.sops.secrets."mailarchiver/.env".path
      ];

      volumes = [
        "${toString cfg.dataDir}:/app/DataProtection-Keys"
      ];
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.listenPort}
            '';
          };
        };
      };

      postgresql = lib.mkIf postgresqlEnabled {
        ensureDatabases = [
          "mailarchiver"
        ];

        ensureUsers = [
          {
            name = "mailarchiver";
            ensureDBOwnership = true;
          }
        ];
      };

      postgresqlBackup = lib.mkIf (postgresqlEnabled && postgresqlBackupEnabled) {
        databases = [
          "mailarchiver"
        ];
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        podman-mailarchiver = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir];
            };
          }

          (lib.mkIf cfg.zfs.enable {
            requires = ["zfs-dataset-mailarchiver.service"];
            after = ["zfs-dataset-mailarchiver.service"];
          })
        ];
      };
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !cfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          cfg.dataDir
        ];
      };
  };
}
