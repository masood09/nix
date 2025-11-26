{
  config,
  lib,
  ...
}: let
  postgresqlCfg = config.homelab.services.postgresql;
in {
  services = lib.mkIf postgresqlCfg.enable {
    postgresql = {
      inherit (postgresqlCfg) enable package dataDir;
    };
  };
}
