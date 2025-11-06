{config, ...}: {
  sops.secrets = {
    "authentik-env" = {
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };

    "restic-env" = {
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
  };

  services = {
    authentik = {
      enable = true;
      environmentFile = config.sops.secrets."authentik-env".path;

      settings = {
        disable_startup_analytics = true;
        avatars = "initials";
      };
    };

    postgresqlBackup = {
      databases = ["authentik"];
    };

    restic.backups.localBackup = {
      initialize = true;
      environmentFile = config.sops.secrets."restic-env".path;
      repositoryFile = config.sops.secrets."restic-repo".path;
      passwordFile = config.sops.secrets."restic-password".path;

      paths = [
        "/var/lib/authentik/"
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
      "/var/lib/authentik"
    ];
  };
}
