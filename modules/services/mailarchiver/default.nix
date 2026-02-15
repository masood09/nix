{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.mailarchiver;
  bridgeCfg = cfg.protonBridge;
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
    homelab.zfs.datasets = {
      mailarchiver = lib.mkIf cfg.zfs.enable {
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

      "mailarchiver-proton-bridge" = lib.mkIf (bridgeCfg.enable && bridgeCfg.zfs.enable) {
        inherit (bridgeCfg.zfs) dataset properties;

        enable = true;
        mountpoint = bridgeCfg.dataDir;

        requiredBy = [
          "podman-mailarchiver-proton-bridge.service"
        ];

        restic = {
          enable = true;
        };
      };
    };

    virtualisation.oci-containers.containers = {
      mailarchiver = {
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

        extraOptions = [
          "--network=mailarchiver-net"
        ];
      };

      "mailarchiver-proton-bridge" = lib.mkIf bridgeCfg.enable {
        # renovate: datasource=docker depName=docker.io/shenxn/protonmail-bridge
        image = "docker.io/shenxn/protonmail-bridge:3.19.0-1";
        autoStart = true;

        # Persist credentials/cache
        volumes = [
          "${toString bridgeCfg.dataDir}:/root"
        ];

        extraOptions = [
          "--network=mailarchiver-net"
          "--network-alias=proton-bridge"
        ];
      };
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
      targets = {
        "podman-compose-mailarchiver" = {
          unitConfig = {
            Description = "Root target for MailArchiver.";
          };

          wantedBy = ["multi-user.target"];

          after =
            (lib.optionals cfg.zfs.enable ["zfs-dataset-mailarchiver.service"])
            ++ (lib.optionals (bridgeCfg.enable && bridgeCfg.zfs.enable) ["zfs-dataset-mailarchiver-proton-bridge.service"]);

          requires =
            (lib.optionals cfg.zfs.enable ["zfs-dataset-mailarchiver.service"])
            ++ (lib.optionals (bridgeCfg.enable && bridgeCfg.zfs.enable) ["zfs-dataset-mailarchiver-proton-bridge.service"]);
        };
      };

      services = {
        "podman-network-mailarchiver-net" = {
          description = "Create podman network mailarchiver-net";
          path = [pkgs.podman];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "podman network rm -f mailarchiver-net";
          };

          script = ''
            podman network inspect mailarchiver-net || podman network create mailarchiver-net
          '';

          partOf = ["podman-compose-mailarchiver.target"];
          wantedBy = ["podman-compose-mailarchiver.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];
        };

        "podman-mailarchiver" = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir];
            };
          }
          {
            partOf = ["podman-compose-mailarchiver.target"];

            wantedBy = ["podman-compose-mailarchiver.target"];
          }
          {
            requires =
              ["podman-network-mailarchiver-net.service"]
              ++ lib.optionals cfg.zfs.enable ["zfs-dataset-mailarchiver.service"];

            after =
              ["podman-network-mailarchiver-net.service"]
              ++ lib.optionals cfg.zfs.enable ["zfs-dataset-mailarchiver.service"];
          }
        ];

        "podman-mailarchiver-proton-bridge" = lib.mkIf bridgeCfg.enable (lib.mkMerge [
          {
            unitConfig = {
              RequiresMountsFor = [bridgeCfg.dataDir];
            };
          }
          {
            partOf = ["podman-compose-mailarchiver.target"];

            wantedBy = ["podman-compose-mailarchiver.target"];
          }
          {
            requires =
              ["podman-network-mailarchiver-net.service"]
              ++ lib.optionals bridgeCfg.zfs.enable ["zfs-dataset-mailarchiver-proton-bridge.service"];

            after =
              ["podman-network-mailarchiver-net.service"]
              ++ lib.optionals bridgeCfg.zfs.enable ["zfs-dataset-mailarchiver-proton-bridge.service"];
          }
        ]);
      };
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
      ) {
        persistence."/nix/persist".directories =
          (lib.optionals (!cfg.zfs.enable) [cfg.dataDir])
          ++ (lib.optionals (bridgeCfg.enable && !bridgeCfg.zfs.enable) [bridgeCfg.dataDir]);
      };
  };
}
