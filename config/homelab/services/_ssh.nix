{lib, ...}: {
  options.homelab.services.ssh = {
    listenPort = lib.mkOption {
      default = 22222;
      type = lib.types.port;
      description = "The port of the SSH server.";
    };

    listenPortBoot = lib.mkOption {
      default = 2222;
      type = lib.types.port;
      description = "The port of the SSH server for remote boot unlock.";
    };
  };
}
