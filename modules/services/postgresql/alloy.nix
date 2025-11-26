{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  postgresqlEnabled = config.homelab.services.postgresql.enable;
in {
  environment.etc."alloy/config-postgresql.alloy" = lib.mkIf (postgresqlEnabled && alloyEnabled) {
    source = ./postgresql.alloy;
  };
}
