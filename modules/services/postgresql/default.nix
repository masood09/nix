{
  config,
  lib,
  ...
}: let
  postgresqlCfg = config.homelab.services.postgresql;
in {
  imports = [
    ./alloy.nix
  ];

  services = lib.mkIf postgresqlCfg.enable {
    postgresql = {
      inherit (postgresqlCfg) enable package dataDir;
    };

    prometheus.exporters.postgres = {
      enable = true;
      listenAddress = "127.0.0.1";
      runAsLocalSuperUser = true;
    };
  };
}
