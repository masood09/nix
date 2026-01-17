{
  config,
  lib,
  ...
}: let
  uptimeKumaCfg = config.homelab.services.uptime-kuma;
in {
  services = {
    restic = {
      backups = {
        s3-oci-backup = {
          initialize = true;
          environmentFile = config.sops.secrets."restic-env".path;
          repositoryFile = config.sops.secrets."restic-repo".path;
          passwordFile = config.sops.secrets."restic-password".path;

          paths =
            [
              # put your always-backed-up paths here
            ]
            ++ lib.optionals uptimeKumaCfg.enable [
              uptimeKumaCfg.dataDir
            ];

          pruneOpts = [
            "--keep-daily 1"
            "--keep-weekly 7"
            "--keep-monthly 30"
            "--keep-yearly 12"
          ];

          timerConfig = {
            OnCalendar = "*-*-* 00,08,16:00:00";
            Persistent = true;
          };
        };
      };
    };
  };
}
