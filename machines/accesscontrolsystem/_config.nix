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

          # The whole StateDirectory, not .../media. authentik only creates
          # media/ on first upload (flow background, application icon), so on a
          # host that has never had one the path does not exist — and restic
          # silently drops paths that are missing rather than failing. The repo
          # shows exactly when that started: snapshots up to 2026-02-01 list
          # media, everything from 2026-07-05 on does not.
          #
          # Pointing at the parent means media is picked up whenever it appears.
          # This is read live rather than from the snapshot, which is fine here:
          # it is ~900K of mostly-static files, and uploaded assets are
          # write-once, so there is no consistency requirement to violate.
          extraPaths = ["/var/lib/private/authentik"];

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
