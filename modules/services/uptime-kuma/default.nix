{
  config,
  lib,
  ...
}: let
  uptimeKumaCfg = config.homelab.services.uptime-kuma;
  caddyEnabled = config.homelab.services.caddy.enable;
in {
  options.homelab.services.uptime-kuma = {
    enable = lib.mkEnableOption "Whether to enable Uptime Kuma.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/uptime-kuma/";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "uptime.mantannest.com";
    };

    userId = lib.mkOption {
      default = 3002;
      type = lib.types.ints.u16;
      description = "User ID of Alloy user";
    };

    groupId = lib.mkOption {
      default = 3002;
      type = lib.types.ints.u16;
      description = "Group ID of Alloy group";
    };
  };

  config = {
    services = lib.mkIf uptimeKumaCfg.enable {
      uptime-kuma = {
        inherit (uptimeKumaCfg) enable;

        settings = {
          DATA_DIR = uptimeKumaCfg.dataDir;
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${uptimeKumaCfg.webDomain}" = {
            useACMEHost = uptimeKumaCfg.webDomain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.uptime-kuma.settings.PORT}
            '';
          };
        };
      };
    };

    security = lib.mkIf (caddyEnabled && uptimeKumaCfg.enable) {
      acme.certs."${uptimeKumaCfg.webDomain}".domain = "${uptimeKumaCfg.webDomain}";
    };

    users = {
      users = lib.optionalAttrs uptimeKumaCfg.enable {
        uptime-kuma = {
          isSystemUser = true;
          group = "uptime-kuma";
          uid = uptimeKumaCfg.userId;
        };
      };

      groups = lib.optionalAttrs uptimeKumaCfg.enable {
        uptime-kuma = {
          gid = uptimeKumaCfg.groupId;
        };
      };
    };

    systemd.services.uptime-kuma = {
      serviceConfig = {
        DynamicUser = lib.mkForce false;

        # stop systemd from trying to manage /var/lib/private + bind-mount behavior
        StateDirectory = lib.mkForce "";
        StateDirectoryMode = lib.mkForce "";

        User = "uptime-kuma";
        Group = "uptime-kuma";

        # with ProtectSystem=strict, you must explicitly allow writes here
        ReadWritePaths = ["/var/lib/uptime-kuma"];
      };
    };
  };
}
