# Options — Home Assistant container (domain, port, firewall, storage, ZFS).
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

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "home.${config.networking.domain}";
            description = "Domain name for the Home Assistant web interface (Caddy vhost).";
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/home-assistant";
            description = "Directory mounted as the container's /config.";
          };

          listenPort = lib.mkOption {
            default = 8920;
            type = lib.types.port;
            description = "Loopback port Caddy proxies to. Home Assistant's own HTTP port must be set to match in its UI (Settings > System > Network > HTTP server); it cannot be set from YAML since 2026.8.";
          };

          openFirewall = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = "Whether to open the LAN discovery ports: mDNS (5353/udp) and HomeKit (21063/tcp).";
          };

          firewallInterfaces = lib.mkOption {
            default = [];
            type = lib.types.listOf lib.types.str;
            example = ["enp1s0f1"];
            description = "Interfaces to open the discovery ports on. Empty means every interface.";
          };

          zfs = zfsOpts {
            serviceName = "Home Assistant";
            dataset = "dpool/tank/services/home-assistant";
            properties = {
              logbias = "latency";
              recordsize = "16K";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
