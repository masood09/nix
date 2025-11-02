{config, ...}: {
  imports = [
    ./_acme.nix
    ./_nginx.nix
    ./_postgresql.nix
  ];

  sops.secrets = {
    "authentik-environment-file" = {
      sopsFile = ./../secrets/authentik-env;
      format = "binary";
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

    postgresqlBackup = {
      databases = ["authentik"];
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
}
