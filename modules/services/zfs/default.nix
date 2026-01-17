{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;

  # Any datasets with enable = true?
  anyManagedDatasets = (lib.attrNames (lib.filterAttrs (_: v: v.enable or false) config.homelab.zfs.datasets)) != [];

  enableZFS = (homelabCfg.isRootZFS or false) || anyManagedDatasets;
in {
  imports = [
    ./alloy.nix
    ./dataset.nix
  ];

  config = lib.mkIf enableZFS {
    services = lib.mkIf (homelabCfg.isRootZFS || anyManagedDatasets) {
      zfs = {
        autoScrub.enable = true;
        autoScrub.interval = "monthly";
        trim.enable = true;
      };

      prometheus.exporters.zfs = lib.mkIf homelabCfg.services.alloy.enable {
        enable = true;
        listenAddress = "127.0.0.1";
      };
    };
  };
}
