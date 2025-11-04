{ config, ... }: {
  imports = [
    ../../../modules/nixos/_pve-restic-secrets.nix
  ];

  services = {
    restic.backups.localbackup = {
      initialize = true;
      environmentFile = config.sops.secrets."restic-env".path;
      repositoryFile = config.sops.secrets."restic-repo".path;
      passwordFile = config.sops.secrets."restic-password".path;

      paths = [
        "/var/lib/vaultwarden"
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
