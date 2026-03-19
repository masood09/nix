# Tailscale — mesh VPN client connecting to the self-hosted Headscale server.
# Auto-authenticates via sops-managed pre-auth key with --accept-routes.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.tailscale;

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "tailscale";
    dataDir = cfg.dataDir;
    user = "root";
    group = "root";
    mainServices = ["tailscaled"];
    zfs = {
      enable = cfg.zfs.enable;
      datasetServiceName = "zfs-dataset-tailscale";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    homelab.zfs.datasets.tailscale = lib.mkIf cfg.zfs.enable {
      inherit (cfg.zfs) dataset properties;

      enable = true;
      mountpoint = cfg.dataDir;
      requiredBy = ["tailscaled.service"];
    };

    services = {
      tailscale = {
        inherit (cfg) enable;

        authKeyFile = config.sops.secrets."tailscale/preauth-key".path;
        disableUpstreamLogging = true;

        extraUpFlags = [
          "--login-server=${cfg.loginServer}"
          "--accept-routes"
        ];
      };
    };

    inherit (permSvc) systemd;

    environment.persistence."/nix/persist" =
      lib.mkIf (
        !homelabCfg.isRootZFS
        && !cfg.zfs.enable
      ) {
        directories = [
          cfg.dataDir
        ];
      };
  };
}
