{lib, ...}: {
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
}
