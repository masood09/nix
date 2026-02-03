{lib, ...}: {
  options.homelab.services = {
    podman = {
      enable = lib.mkEnableOption "Whether to enable Podman.";

      zfs = {
        enable = lib.mkEnableOption "Store Podman dataDir on a ZFS dataset.";

        dataset = lib.mkOption {
          type = lib.types.str;
          default = "dpool/tank/services/podman";
          description = "ZFS dataset to create and mount at dataDir.";
        };

        properties = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            logbias = "latency";
            recordsize = "16K";
          };
          description = "ZFS properties for the dataset.";
        };
      };
    };
  };
}
