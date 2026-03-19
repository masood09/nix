# Options — Nightscout CGM dashboard (domain, port, title).
{
  config,
  lib,
  ...
}: {
  options = {
    homelab = {
      services = {
        nightscout = {
          enable = lib.mkEnableOption "Whether to enable Nightscout.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "nightscout.${config.networking.domain}";
            description = "Domain name for the Nightscout web interface.";
          };

          listenAddress = lib.mkOption {
            default = "127.0.0.1";
            type = lib.types.str;
            description = "Address for Nightscout to bind to.";
          };

          port = lib.mkOption {
            default = 8914;
            type = lib.types.port;
            description = "Port for the Nightscout web server.";
          };

          openFirewall = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = "Whether to open the listen port in the firewall.";
          };

          userId = lib.mkOption {
            default = 3013;
            type = lib.types.ints.u16;
            description = "UID for the Nightscout service user.";
          };

          groupId = lib.mkOption {
            default = 3013;
            type = lib.types.ints.u16;
            description = "GID for the Nightscout service group.";
          };

          customTitle = lib.mkOption {
            type = lib.types.str;
            default = "Masood Ahmed";
            description = "Custom title displayed in the Nightscout web UI.";
          };
        };
      };
    };
  };
}
