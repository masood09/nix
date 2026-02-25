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
          ENABLE = "careportal basal dbsize rawbg iob maker cob bwp cage iage sage boluscalc pushover treatmentnotify loop pump profile food openaps bage alexa override speech cors";
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
