# Shared ZFS option builder — generates the enable/dataset/properties option
# set reused by every service that supports ZFS-backed storage.
{lib}: {
  # mkZfsOptions: generates the standard zfs option set used by most services.
  #
  # Arguments:
  #   serviceName - human-readable name (e.g. "Grafana")
  #   dataset     - default ZFS dataset path
  #   properties  - default ZFS properties attrset
  #   withRestic  - whether to include restic.enable option (default: false)
  mkZfsOptions = {
    serviceName,
    dataset,
    properties ? {},
    withRestic ? false,
  }:
    {
      enable = lib.mkEnableOption "Store ${serviceName} dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = dataset;
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = properties;
        description = "ZFS properties for the dataset.";
      };
    }
    // lib.optionalAttrs withRestic {
      restic = {
        enable = lib.mkEnableOption "Whether to enable restic backup.";
      };
    };
}
