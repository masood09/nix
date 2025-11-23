{lib, ...}: {
  options.homelab.networking = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = ''
        The hostname of the machine.
      '';
    };

    wireless_enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
  };
}
