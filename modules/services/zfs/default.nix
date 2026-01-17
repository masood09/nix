{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;

  # Any datasets with enable = true?
  anyManagedDatasets = (lib.attrNames (lib.filterAttrs (_: v: v.enable or false) config.homelab.zfs.datasets)) != [];
in {
  imports = [
    ./dataset.nix
  ];

  config = {
    services = lib.mkIf (homelabCfg.isRootZFS || anyManagedDatasets) {
      zfs = {
        autoScrub.enable = true;
        autoScrub.interval = "monthly";
        trim.enable = true;
      };
    };
  };
}
