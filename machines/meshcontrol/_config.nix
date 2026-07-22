# Homelab options — mesh networking control plane (Headscale + Headplane).
{
  config = {
    homelab = {
      purpose = "Mesh Networking Control Plane (Headscale)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      hardware = {
        isVM = true;
      };

      networking = {
        hostName = "meshcontrol";
      };

      programs = {
        fastfetch = {
          zpools = ["rpool"];
        };
      };

      services = {
        acme = {
          zfs = {
            enable = true;
          };
        };

        backup = {
          enable = true;

          # No services are stopped. Both units keep all their state in a
          # single ZFS dataset (headscale -> /var/lib/headscale, headplane ->
          # its own dataDir), so one atomic snapshot captures a crash-consistent
          # view — the same guarantee the process already has to survive a power
          # cut. headscale is SQLite with write_ahead_log = true, and the db,
          # -wal and -shm files all live inside that one dataset, so SQLite
          # recovers them on open exactly as it would after a hard reset.
          #
          # Stopping them also had a cross-host cost: headscale sets
          # only_start_if_oidc_is_available (hscontrol/app.go:171), so it exits
          # fatally if authentik is unreachable at startup. Restarting it at
          # 02:00 — the same minute accesscontrolsystem stopped authentik for
          # its own backup — crash-looped it 8 times and took the tailnet down
          # for ~50s. Not restarting it removes that coupling entirely.
          serviceUnits = [];
        };

        caddy = {
          enable = true;
        };

        headscale = {
          enable = true;

          oidc = {
            enable = true;
          };

          zfs = {
            enable = true;
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
