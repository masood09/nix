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

  options = {
    homelab = {
      isRootZFS = lib.mkEnableOption "Whether the root drive is ZFS.";
    };
  };

  config = lib.mkIf enableZFS {
    boot = {
      zfs = {
        # Adopt the 26.11 default early: don't force-import a pool that wasn't
        # cleanly exported. Safer against data loss (e.g. a disk imported by
        # another system) and silences the pre-26.11 deprecation warning.
        forceImportRoot = false;
      };
    };

    services = lib.mkIf (homelabCfg.isRootZFS || anyManagedDatasets) {
      zfs = {
        autoScrub = {
          enable = true;
          interval = "monthly";
        };

        trim = {
          enable = true;
        };
      };

      prometheus = {
        exporters = {
          # ZFS metrics for Prometheus via Alloy
          zfs = lib.mkIf homelabCfg.services.alloy.enable {
            enable = true;
            listenAddress = "127.0.0.1";
          };
        };
      };
    };
  };
}
