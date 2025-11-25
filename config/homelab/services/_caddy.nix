{lib, ...}: {
  options.homelab.services.caddy = {
    enable = lib.mkEnableOption "Whether to enable Caddy web server.";
  };
}
