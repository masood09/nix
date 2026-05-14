# Options — heartbeat-only Minecraft stack backed by nix-minecraft.
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
        minecraft = {
          enable = lib.mkEnableOption "Whether to enable the Minecraft server stack on heartbeat.";

          openFirewall = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = "Whether to open the public Minecraft proxy port in the firewall.";
          };

          hostDomain = lib.mkOption {
            default = "minecraft.${config.networking.domain}";
            type = lib.types.str;
            description = "Base domain for Velocity forced-host routing. Server names are prefixed to this domain.";
          };

          zfs = zfsOpts {
            serviceName = "Minecraft";
            dataset = "fpool/fast/services/minecraft";
            properties = {
              recordsize = "128K";
              redundant_metadata = "most";
            };
          };
        };
      };
    };
  };
}
