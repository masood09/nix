{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  headscaleCfg = homelabCfg.services.headscale;
  caddyEnabled = homelabCfg.services.caddy.enable;
in {
  imports = [
    ./acl.nix
    ./dns.nix
    ./oidc.nix
  ];

  options.homelab.services.headscale = {
    enable = lib.mkEnableOption "Whether to enable Headscale.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/headscale/";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "headscale.${config.networking.domain}";
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      default = "admin@ahmedmasood.com";
    };

    metricsPort = lib.mkOption {
      default = 9091;
      type = lib.types.port;
    };

    oidc = {
      enable = lib.mkEnableOption "Enable OIDC";

      issuer = lib.mkOption {
        type = lib.types.str;
        default = "https://auth.${config.networking.domain}/application/o/headscale/";
      };

      client_id = lib.mkOption {
        type = lib.types.str;
        default = "Pjad107mj4JsZRnmbTMzbGiNqIolCMFn2jF3dBeA";
      };

      client_secret_path = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets."headscale-authentik-client-secret".path;
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store Headscale dataDir on a ZFS dataset.";

      restic = {
        enable = lib.mkEnableOption "Enable restic backup";
      };

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "rpool/root/var/lib/headscale";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          recordsize = "16K";
        };
        description = "ZFS properties for the dataset.";
      };
    };
  };

  config = lib.mkIf headscaleCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.headscale = lib.mkIf headscaleCfg.zfs.enable {
      inherit (headscaleCfg.zfs) dataset properties;

      enable = true;
      mountpoint = headscaleCfg.dataDir;
      requiredBy = ["headscale.service"];

      restic = {
        enable = true;
      };
    };

    services = {
      headscale = {
        inherit (headscaleCfg) enable;

        settings = {
          logtail.enabled = false;
          server_url = "https://${headscaleCfg.webDomain}";
          metrics_listen_addr = "127.0.0.1:${toString headscaleCfg.metricsPort}";
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${headscaleCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.headscale.port}
            '';
          };
        };
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services.headscale = lib.mkMerge [
        {
          # Unit-level ordering / mount requirements
          unitConfig = {
            RequiresMountsFor = [headscaleCfg.dataDir];
          };
        }

        (lib.mkIf headscaleCfg.zfs.enable {
          requires = ["zfs-dataset-headscale.service"];
          after = ["zfs-dataset-headscale.service"];
        })
      ];

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${headscaleCfg.dataDir} 0750 headscale headscale -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !headscaleCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          headscaleCfg.dataDir
        ];
      };
  };
}
