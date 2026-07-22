# Homelab options — identity & access control server (Authentik SSO).
{
  config = {
    homelab = {
      purpose = "Identity & Access Control (SSO / Authentik)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      hardware = {
        isVM = true;
      };

      networking = {
        hostName = "accesscontrolsystem";
      };

      programs = {
        fastfetch = {
          zpools = ["rpool"];
        };
      };

      services = {
        authentik = {
          enable = true;
        };

        acme = {
          zfs = {
            enable = true;
          };
        };

        backup = {
          enable = true;

          extraPaths = ["/var/lib/private/authentik/media"];

          # No services are stopped. The stop window bought nothing here and
          # cost ~41s of SSO downtime nightly:
          #
          #   - The only restic-enabled dataset is postgresql-backup, i.e. the
          #     pg_dump output. pg_dump is MVCC-consistent by construction, so
          #     quiescing authentik around it changes nothing.
          #   - The media directory is an extraPath, and restic reads extraPaths
          #     live — the pipeline restarts services *before* the upload runs.
          #     The stop window never covered it for a single second.
          #
          # It also cost more than downtime: authentik-worker ignores SIGTERM
          # long enough to hit its 10s stop timeout, so it was SIGKILLed every
          # night mid-task, and the resulting authentik restart took headscale
          # on meshcontrol down with it (OIDC issuer unreachable at startup).
          serviceUnits = [];
        };

        caddy = {
          enable = true;
        };

        postgresql = {
          enable = true;

          zfs = {
            enable = true;
            dataset = "rpool/root/var/lib/postgresql/17";
          };

          backup = {
            enable = true;

            zfs = {
              enable = true;
              dataset = "rpool/root/var/backup/postgresql";
            };
          };
        };

        tailscale = {
          enable = true;

          zfs = {
            enable = true;
          };
        };
      };
    };
  };
}
