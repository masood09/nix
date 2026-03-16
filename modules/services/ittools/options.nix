{
  config,
  lib,
  ...
}: {
  options.homelab.services.ittools = {
    enable = lib.mkEnableOption "Whether to enable IT-Tools.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "ittools.${config.networking.domain}";
      description = "Domain name for the IT-Tools web interface.";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
      description = "Address for IT-Tools to bind to.";
    };

    listenPort = lib.mkOption {
      default = 8901;
      type = lib.types.port;
      description = "Port for the IT-Tools web server.";
    };
  };
}
