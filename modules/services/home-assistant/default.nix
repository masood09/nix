# Home Assistant — local home automation service with declarative system setup.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.home-assistant;
  caddyEnabled = config.services.caddy.enable;

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "home-assistant";
    inherit (cfg) dataDir;
    user = "hass";
    group = "hass";
    mode = "0750";
    mainServices = ["home-assistant"];
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
    homelab = {
      zfs = {
        datasets = {
          home-assistant = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = cfg.dataDir;
            requiredBy = ["home-assistant.service"];

            restic = {
              inherit (cfg.zfs.restic) enable;
            };
          };
        };
      };
    };

    services = {
      home-assistant = {
        enable = true;
        configDir = cfg.dataDir;

        # These integrations are configured through Home Assistant's UI, so
        # list them here to keep their Python dependencies in the Nix package.
        extraComponents = [
          "analytics"
          "brother"
          "google_translate"
          "homekit_controller"
          "isal"
          "lutron_caseta"
          "met"
          "radio_browser"
          "shopping_list"
          "tplink"
          "zeroconf"
        ];

        config = {
          default_config = {};

          homeassistant = {
            name = "Home";
            external_url = "https://${cfg.webDomain}";
            time_zone = "America/Toronto";
            unit_system = "metric";
          };

          http = {
            server_port = 8123;
            server_host = "127.0.0.1";
            trusted_proxies = ["127.0.0.1"];
            use_x_forwarded_for = true;
          };
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;

            extraConfig = ''
              reverse_proxy http://127.0.0.1:8123
            '';
          };
        };
      };
    };

    inherit (permSvc) systemd;

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = cfg.zfs.enable;
      directories = [cfg.dataDir];
    };

    networking = {
      firewall = {
        # HomeKit Controller discovery and pairing use mDNS plus the
        # controller's local TCP listener. The web UI remains behind Caddy.
        allowedTCPPorts = [21063];
        allowedUDPPorts = [5353];
      };
    };
  };
}
