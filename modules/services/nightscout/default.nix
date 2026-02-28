{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.nightscout;
  caddyEnabled = config.services.caddy.enable;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    services = {
      nightscout = {
        enable = true;

        inherit (cfg) port;

        environmentFile = config.sops.secrets."nightscout/.env".path;

        environment = {
          ENABLE = "loop pump iob cob basal careportal sage cage bage override dbsize";
          DEVICESTATUS_ADVANCED = "true";
          PUMP_FIELDS = "battery reservoir clock status";
          PUMP_RETRO_FIELDS = "battery reservoir clock status";
          SHOW_FORECAST = "loop";
          SHOW_PLUGINS = "loop pump cob iob sage cage careportal basal override dbsize";
          LOOP_ENABLE_ALERTS = "true";
          LOOP_WARN = "20";
          LOOP_URGENT = "60";
          BASAL_RENDER = "default";

          BASE_URL = "https://${cfg.webDomain}";
          TIME_FORMAT = "24h";
          THEME = "colors";
          HOSTNAME = cfg.listenAddress;
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.port}
            '';
          };
        };
      };
    };

    users = {
      users.nightscout = {
        uid = cfg.userId;
      };

      groups.nightscout = {
        gid = cfg.groupId;
      };
    };
  };
}
