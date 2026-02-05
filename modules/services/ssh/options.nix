{lib, ...}: {
  options.homelab.services.ssh = {
    listenPort = lib.mkOption {
      default = 22222;
      type = lib.types.port;
      description = "The port of the SSH server.";
    };
  };
}
