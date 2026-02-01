{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.tailscale;
in {
  options.homelab.services.tailscale = {
    enable = lib.mkEnableOption "Enable Tailscale.";

    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://headscale.mantannest.com";
      description = "Control server URL passed to `tailscale up --login-server`.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/tailscale";
      description = "Tailscale state directory. If ZFS is enabled, the dataset is mounted here.";
    };

    zfs = {
      enable = lib.mkEnableOption "Store Tailscale dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "rpool/root/var/lib/tailscale";
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

  config = {
    homelab.zfs.datasets.tailscale = lib.mkIf (cfg.enable && cfg.zfs.enable) {
      inherit (cfg.zfs) dataset properties;

      enable = true;
      mountpoint = cfg.dataDir;
      requiredBy = ["tailscaled.service"];
    };

    services = lib.mkIf cfg.enable {
      tailscale = {
        inherit (cfg) enable;

        authKeyFile = config.sops.secrets."headscale-preauth.key".path;

        extraUpFlags = [
          "--login-server=${cfg.loginServer}"
        ];
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services.tailscaled = lib.mkMerge [
        {
          # Unit-level ordering / mount requirements
          unitConfig = {
            RequiresMountsFor = [cfg.dataDir];
          };
        }

        (lib.mkIf cfg.zfs.enable {
          requires = ["zfs-dataset-tailscale.service"];
          after = ["zfs-dataset-tailscale.service"];
        })
      ];
    };

    environment.persistence."/nix/persist" =
      lib.mkIf (
        !homelabCfg.isRootZFS
        && cfg.enable
        && !cfg.zfs.enable
      ) {
        directories = [
          cfg.dataDir
        ];
      };
  };
}
