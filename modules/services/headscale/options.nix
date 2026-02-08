{
  config,
  lib,
  ...
}: {
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

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "headscale";
      };
    };

    headplane = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/headplane/";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8909;
      };

      zfs = {
        enable = lib.mkEnableOption "Store Headplane dataDir on a ZFS dataset.";

        restic = {
          enable = lib.mkEnableOption "Enable restic backup";
        };

        dataset = lib.mkOption {
          type = lib.types.str;
          default = "rpool/root/var/lib/headplane";
          description = "ZFS dataset to create and mount at dataDir.";
        };

        properties = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            logbias = "latency";
            recordsize = "16K";
            redundant_metadata = "most";
          };
          description = "ZFS properties for the dataset.";
        };
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
          logbias = "latency";
          recordsize = "16K";
          redundant_metadata = "most";
        };
        description = "ZFS properties for the dataset.";
      };
    };
  };
}
