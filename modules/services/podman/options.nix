{lib, ...}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options.homelab.services = {
    podman = {
      enable = lib.mkEnableOption "Whether to enable Podman.";

      zfs = zfsOpts {
        serviceName = "Podman";
        dataset = "dpool/tank/services/podman";
        properties = {
          logbias = "latency";
          recordsize = "16K";
        };
      };
    };
  };
}
