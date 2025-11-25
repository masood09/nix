{
  config,
  lib,
  ...
}: let
  caddyEnabled = config.homelab.services.caddy.enable;
in {
  services.caddy = {
    enable = caddyEnabled;
  };

  networking.firewall.allowedTCPPorts = lib.mkIf caddyEnabled [
    80
    443
  ];
}
