# Uptime Kuma — service health monitoring with status pages and notifications.
# Runs as a dedicated user (not DynamicUser) for ZFS dataset compatibility.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  uptimeKumaCfg = homelabCfg.services.uptime-kuma;
  caddyEnabled = homelabCfg.services.caddy.enable;

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "uptime-kuma";
    dataDir = uptimeKumaCfg.dataDir;
    user = "uptime-kuma";
    group = "uptime-kuma";
    mode = "0750";
    mainServices = ["uptime-kuma"];
    zfs = {
      enable = uptimeKumaCfg.zfs.enable;
      datasetServiceName = "zfs-dataset-uptime-kuma";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf uptimeKumaCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.uptime-kuma = lib.mkIf uptimeKumaCfg.zfs.enable {
      inherit (uptimeKumaCfg.zfs) dataset properties;

      enable = true;
      mountpoint = uptimeKumaCfg.dataDir;
      requiredBy = ["uptime-kuma.service"];

      restic = {
        enable = true;
      };
    };

    services = {
      uptime-kuma = {
        inherit (uptimeKumaCfg) enable;

        settings = {
          DATA_DIR = uptimeKumaCfg.dataDir;
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${uptimeKumaCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.uptime-kuma.settings.PORT}
            '';
          };
        };
      };
    };

    users = {
      users = {
        uptime-kuma = {
          isSystemUser = true;
          group = "uptime-kuma";
          uid = uptimeKumaCfg.userId;
        };
      };

      groups = {
        uptime-kuma = {
          gid = uptimeKumaCfg.groupId;
        };
      };
    };

    systemd = lib.mkMerge [
      permSvc.systemd
      {
        services.uptime-kuma.serviceConfig = {
          DynamicUser = lib.mkForce false;
          StateDirectory = lib.mkForce null;
          StateDirectoryMode = lib.mkForce null;
          User = "uptime-kuma";
          Group = "uptime-kuma";
          ReadWritePaths = [uptimeKumaCfg.dataDir];
        };
      }
    ];

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !uptimeKumaCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          uptimeKumaCfg.dataDir
        ];
      };
  };
}
