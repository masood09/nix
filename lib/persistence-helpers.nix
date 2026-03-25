# Persistence helper — generates impermanence bind-mount config for service
# data directories. Skips bind-mounts when ZFS handles persistence.
#
# Decision matrix:
#   impermanence  isRootZFS  zfsEnable  → bind-mount?
#   true          true       *          → no  (ZFS root survives rollback)
#   true          false      true       → no  (dedicated dataset persists)
#   true          false      false      → YES (data lost without bind-mount)
#   false         *          *          → no  (root persists naturally)
{lib}: {
  # mkPersistenceDirs: generates environment.persistence for a service.
  #
  # Arguments:
  #   homelabCfg  - config.homelab attrset
  #   zfsEnable   - whether the service's ZFS dataset is enabled (default: false)
  #   directories - list of paths to persist under /nix/persist
  mkPersistenceDirs = {
    homelabCfg,
    zfsEnable ? false,
    directories,
  }:
    lib.mkIf (
      homelabCfg.impermanence
      && !homelabCfg.isRootZFS
      && !zfsEnable
    ) {
      persistence = {
        "/nix/persist" = {
          inherit directories;
        };
      };
    };
}
