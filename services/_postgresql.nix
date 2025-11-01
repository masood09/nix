{pkgs, ...}: {
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

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/postgresql"
    ];
  };
}
