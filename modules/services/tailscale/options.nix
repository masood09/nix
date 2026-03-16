{lib, ...}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options.homelab.services.tailscale = {
    enable = lib.mkEnableOption "Whether to enable Tailscale.";

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

    zfs = zfsOpts {
      serviceName = "Tailscale";
      dataset = "rpool/root/var/lib/tailscale";
      properties = {
        recordsize = "16K";
      };
    };
  };
}
