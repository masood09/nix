{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    "authentik-environment-file" = {
      owner = "root";
      group = "root";
      mode = "0400";
      sopsFile = ./../secrets/oci-authentik.yaml;
    };

    "restic-env-file" = {
      sopsFile = ./../secrets/oci-restic.yaml;
    };
    "restic-oci-repo" = {
      sopsFile = ./../secrets/oci-restic.yaml;
    };
    "restic-encrypt-password" = {
      sopsFile = ./../secrets/oci-restic.yaml;
    };
  };

  services = {
    authentik = {
      enable = true;
      environmentFile = config.sops.secrets."authentik-environment-file".path;
      settings = {
        disable_startup_analytics = true;
        avatars = "initials";
      };
      nginx = {
        enable = true;
        enableACME = true;
        host = "auth.mantannest.com";
      };
    };

    postgresql = {
      package = pkgs.postgresql_16;
    };

    postgresqlBackup = {
      enable = true;

      databases = [
        "authentik"
      ];

      pgdumpOptions = "--no-owner";
      startAt = "*-*-* *:15:00";
    };

    restic.backups.postgresql = {
      initialize = true;
      environmentFile = config.sops.secrets."restic-env-file".path;
      repositoryFile = config.sops.secrets."restic-oci-repo".path;
      passwordFile = config.sops.secrets."restic-encrypt-password".path;

      paths = [
        "/var/backup/postgresql/"
      ];

      pruneOpts = [
        "--keep-daily 24"
        "--keep-weekly 7"
        "--keep-monthly 30"
        "--keep-yearly 12"
      ];

      timerConfig = {
        OnCalendar = "*-*-* *:30:00";
        Persistent = true;
      };
    };
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/postgresql"
    ];
  };
}
