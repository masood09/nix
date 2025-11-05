{ config, ... }: {
  sops.secrets = {
    "restic-env" = {
      sopsFile = ./../../../secrets/pve-monitoring.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../../secrets/pve-monitoring.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../../secrets/pve-monitoring.yaml;
    };
  };

  services = {
    restic.backups.localBackup = {
      initialize = true;
      environmentFile = config.sops.secrets."restic-env".path;
      repositoryFile = config.sops.secrets."restic-repo".path;
      passwordFile = config.sops.secrets."restic-password".path;

      paths = [

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
