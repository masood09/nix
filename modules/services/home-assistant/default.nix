# Home Assistant — home automation running as a Podman OCI container.
# Uses host networking so mDNS/multicast discovery (HomeKit, zeroconf) works.
# Persistent state lives in a ZFS dataset. Configuration is managed in the UI
# and in the dataset's YAML files; Nix only seeds the starter files once.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.home-assistant;
  caddyEnabled = config.services.caddy.enable;

  discoveryPorts = {
    allowedTCPPorts = [21063]; # HomeKit
    allowedUDPPorts = [5353]; # mDNS
  };

  # Starter configuration.yaml, written only when the file does not exist.
  # Plain text rather than pkgs.formats.yaml, because it needs !include tags.
  #
  # There is deliberately no http block: since 2026.8 Home Assistant ignores
  # YAML HTTP settings after a one-time migration and requires them to be set
  # and confirmed in Settings > System > Network > HTTP server. Set the port to
  # cfg.listenPort, the host to 127.0.0.1, and trust 127.0.0.1 as a proxy
  # there; Caddy below proxies to that port. Set both Home Assistant URLs
  # (internet and local network) to https://<webDomain> on the same page.
  seedConfig = pkgs.writeText "home-assistant-configuration.yaml" ''
    # Seeded once by the NixOS home-assistant module on first start. Nix never
    # overwrites this file, so edit it freely and restart the container.
    #
    # HTTP server settings (port, listen address, trusted proxies) and the
    # Home Assistant URLs live in the UI under Settings > System > Network.
    # Setting them here would lock those UI fields.

    default_config:

    # Files the UI editors save automations, scripts and scenes into.
    automation: !include automations.yaml
    script: !include scripts.yaml
    scene: !include scenes.yaml
  '';

  # Copies each starter file into dataDir only if it is missing, so later
  # edits (by hand or from the UI) always win.
  seedScript = pkgs.writeShellScript "home-assistant-seed" ''
    set -eu
    seed() {
      if [ ! -e "$2" ]; then
        ${pkgs.coreutils}/bin/install -m 0640 -o root -g root "$1" "$2"
        echo "seeded $2"
      fi
    }
    seed ${seedConfig} ${cfg.dataDir}/configuration.yaml
    seed ${pkgs.writeText "automations.yaml" "[]\n"} ${cfg.dataDir}/automations.yaml
    seed ${pkgs.writeText "scripts.yaml" ""} ${cfg.dataDir}/scripts.yaml
    seed ${pkgs.writeText "scenes.yaml" ""} ${cfg.dataDir}/scenes.yaml
  '';

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "home-assistant";
    inherit (cfg) dataDir;
    # The upstream image runs as root inside the container.
    user = "root";
    group = "root";
    mode = "0750";
    mainServices = ["podman-home-assistant"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-home-assistant";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = homelabCfg.services.podman.enable;
        message = "Home Assistant requires Podman (homelab.services.podman.enable).";
      }
    ];

    homelab = {
      zfs = {
        datasets = {
          home-assistant = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = cfg.dataDir;

            requiredBy = [
              "podman-home-assistant.service"
            ];

            restic = {
              inherit (cfg.zfs.restic) enable;
            };
          };
        };
      };
    };

    virtualisation = {
      oci-containers = {
        containers = {
          home-assistant = {
            # renovate: datasource=docker depName=ghcr.io/home-assistant/home-assistant
            image = "ghcr.io/home-assistant/home-assistant:2026.11.1";
            autoStart = true;

            volumes = [
              "${toString cfg.dataDir}:/config"
            ];

            environment = {
              TZ = config.time.timeZone;
            };

            # Host networking: discovery relies on mDNS/multicast, which does
            # not cross the Podman bridge. The HTTP listener's port and
            # loopback binding are set in Home Assistant's UI (see seedConfig).
            extraOptions = [
              "--network=host"
              # DHCP-based discovery sniffs raw packets, and the Bluetooth
              # manager needs both to recover adapters; without them both log
              # "Operation not permitted" on every start.
              "--cap-add=NET_ADMIN"
              "--cap-add=NET_RAW"
            ];
          };
        };
      };
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.listenPort}
            '';
          };
        };
      };
    };

    systemd = lib.mkMerge [
      permSvc.systemd
      {
        services = {
          home-assistant-seed = {
            description = "Seed Home Assistant starter config files if missing";
            after = ["home-assistant-permissions.service"];
            requires = ["home-assistant-permissions.service"];
            before = ["podman-home-assistant.service"];
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir];
            };
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = seedScript;
            };
          };

          podman-home-assistant = {
            requires = ["home-assistant-seed.service"];
            after = ["home-assistant-seed.service"];
          };
        };
      }
    ];

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = cfg.zfs.enable;
      directories = [cfg.dataDir];
    };

    # LAN discovery only; the web UI stays on loopback behind Caddy.
    networking = {
      firewall = lib.mkIf cfg.openFirewall (
        if cfg.firewallInterfaces == []
        then discoveryPorts
        else {
          interfaces = lib.genAttrs cfg.firewallInterfaces (_: discoveryPorts);
        }
      );
    };
  };
}
