{lib, ...}: {
  options.homelab.disks = {
    root = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Disk-by-id list for the root pool";
    };

    fast = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Disk-by-id list for the fast pool";
    };

    data = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Disk-by-id list for the data pool";
    };
  };
}
