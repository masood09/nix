{
  config,
  pkgs,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  services = {
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
    };

    postgresqlBackup = {
      enable = true;
      pgdumpOptions = "--no-owner";
      startAt = "*-*-* *:15:00";
    };
  };

  environment.persistence."/nix/persist" = lib.mkIf (!homelabCfg.isRootZFS) {
    directories = [
      "/var/lib/postgresql"
    ];
  };
}
