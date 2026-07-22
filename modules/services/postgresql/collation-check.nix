# PostgreSQL sub-module — collation drift detector.
#
# A glibc upgrade can change collation ordering, leaving every database's text
# indexes sorted under the old rules until they are rebuilt. PostgreSQL only
# whispers about it (a notice on connect), so the drift is invisible unless a
# client happens to log notices — authentik does, immich/vaultwarden/matrix do
# not. This timer makes the whisper loud: it logs at journal priority `err`,
# which Alloy ships to Loki, so drift shows up in `{level="error"}`.
#
# Remediation when it fires, per stale database:
#   sudo -u postgres reindexdb --concurrently -d <db>
#   sudo -u postgres psql -c 'ALTER DATABASE "<db>" REFRESH COLLATION VERSION'
{
  config,
  lib,
  pkgs,
  ...
}: let
  postgresqlCfg = config.homelab.services.postgresql;
  checkCfg = postgresqlCfg.collationCheck;

  # Databases whose recorded collation version no longer matches the running
  # OS. `datcollversion IS NULL` means the provider does not track versions
  # (C locale), so there is nothing to compare and nothing to rebuild.
  # string_agg returns NULL when nothing is stale, which psql -tA prints as an
  # empty line — deliberately not wrapped in coalesce(..., '') because a pair
  # of single quotes would terminate this Nix indented string.
  staleQuery = ''
    SELECT string_agg(datname || ' (' || datcollversion || ')', ', ' ORDER BY datname)
    FROM pg_database
    WHERE datallowconn
      AND datcollversion IS NOT NULL
      AND datcollversion <> pg_collation_actual_version(
        (SELECT oid FROM pg_collation WHERE collname = 'default')
      )
  '';

  checkScript = pkgs.writeShellApplication {
    name = "postgresql-collation-check";

    runtimeInputs = [
      config.services.postgresql.package
    ];

    text = ''
      stale="$(psql -tAX -c "${staleQuery}")"

      # `<3>` / `<6>` are syslog priority prefixes; systemd maps them onto the
      # journal record, which is what gives the Alloy pipeline its `level`.
      if [ -n "$stale" ]; then
        printf '<3>collation drift: %s no longer match the OS collation version; text indexes need REINDEX + REFRESH COLLATION VERSION\n' "$stale"
      else
        printf '<6>collation check: all databases match the OS collation version\n'
      fi
    '';
  };
in {
  config = lib.mkIf (postgresqlCfg.enable && checkCfg.enable) {
    systemd = {
      services = {
        postgresql-collation-check = {
          description = "Check PostgreSQL databases for collation version drift";

          # Reports drift rather than failing on it: a failed unit would be a
          # second, noisier signal for something that is not an outage.
          serviceConfig = {
            Type = "oneshot";
            User = "postgres";
            Group = "postgres";
            ExecStart = lib.getExe checkScript;

            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateTmp = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectSystem = "strict";
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            SystemCallArchitectures = "native";
          };

          after = ["postgresql.service"];
          requires = ["postgresql.service"];

          inherit (checkCfg) startAt;
        };
      };

      timers = {
        postgresql-collation-check = {
          timerConfig = {
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        };
      };
    };
  };
}
