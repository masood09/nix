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

    authKeyFile = lib.mkOption {
      type = lib.types.path;
      default = config.sops.secrets."headscale-preauth-key".path;
      description = "Path to the Tailscale/Headscale preauth key file.";
      example = "/run/secrets/headscale-preauth-key";
    };

    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://headscale.mantannest.com";
      description = "Control server URL passed to `tailscale up --login-server`.";
      example = "https://headscale.example.com";
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
        inherit (cfg) authKeyFile enable;

        extraUpFlags = [
          "--login-server=${cfg.loginServer}"
        ];
      };
    };

    # Make systemd enforce the mount is present
    systemd.services.tailscaled = lib.mkIf (cfg.enable && cfg.zfs.enable) {
      unitConfig = {
        RequiresMountsFor = [cfg.dataDir];
      };

      requires = ["zfs-dataset-tailscale.service"];
      after = ["zfs-dataset-tailscale.service"];
    };

    environment.persistence."/nix/persist" = lib.mkIf (!homelabCfg.isRootZFS && cfg.enable && !cfg.zfs.enable) {
      directories = [
        cfg.dataDir
      ];
    };
  };
}
