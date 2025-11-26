{
  lib,
  pkgs,
  ...
}: {
  options.homelab.services.postgresql = {
    enable = lib.mkEnableOption "Whether to enable PostgreSQL database.";
    package = lib.mkPackageOption pkgs "postgresql_16" { };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/postgresql/16";
    };
  };
}
