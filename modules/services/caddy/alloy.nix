{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  caddyEnabled = config.homelab.services.caddy.enable;
in {
  environment.etc."alloy/config-caddy.alloy" = lib.mkIf (caddyEnabled && alloyEnabled) {
    source = ./caddy.alloy;
  };

  users = lib.mkIf(caddyEnabled && alloyEnabled) {
    users.alloy = {
      extraGroups = [config.services.caddy.group];
    };
  };
}
