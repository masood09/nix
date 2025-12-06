{lib, ...}: {
  options.homelab.services.alloy = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Whether to enable Grafana Alloy.
      '';
    };

    userId = lib.mkOption {
      default = 3000;
      type = lib.types.ints.u16;
      description = "User ID of Alloy user";
    };

    groupId = lib.mkOption {
      default = 3000;
      type = lib.types.ints.u16;
      description = "Group ID of Alloy group";
    };
  };
}
