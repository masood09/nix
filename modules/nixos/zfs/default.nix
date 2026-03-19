# ZFS management — auto-scrub, trim, metrics export, and sub-modules for
# dataset provisioning (dataset.nix), Discord notifications (notification.nix),
# and Alloy/Prometheus scraping (alloy.nix).
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;

  anyManagedDatasets = (lib.attrNames (lib.filterAttrs (_: v: v.enable or false) homelabCfg.zfs.datasets)) != [];

  enableZFS = (homelabCfg.isRootZFS or false) || anyManagedDatasets;
in {
  imports = [
    ./alloy.nix
    ./dataset.nix
    ./notification.nix
  ];

  options.homelab = {
    isRootZFS = lib.mkEnableOption "Whether the root drive is ZFS.";
  };

  config = lib.mkIf enableZFS {
    services = lib.mkIf (homelabCfg.isRootZFS || anyManagedDatasets) {
      zfs = {
        autoScrub.enable = true;
        autoScrub.interval = "monthly";
        trim.enable = true;
      };

      # ZFS metrics for Prometheus via Alloy
      prometheus.exporters.zfs = lib.mkIf homelabCfg.services.alloy.enable {
        enable = true;
        listenAddress = "127.0.0.1";
      };
    };
  };
}
