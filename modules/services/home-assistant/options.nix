# Options — Home Assistant (domain, persistent storage, and ZFS).
{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        home-assistant = {
          enable = lib.mkEnableOption "Whether to enable Home Assistant.";

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/hass";
            description = "Directory for Home Assistant persistent state.";
          };

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "home.${config.networking.domain}";
            description = "Hostname for the Home Assistant web interface.";
          };

          zfs = zfsOpts {
            serviceName = "Home Assistant";
            dataset = "dpool/tank/services/home-assistant";
            properties = {
              recordsize = "16K";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
