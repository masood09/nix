{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    "postgres-password" = {
      owner = "postgres";
      group = "postgres";
      mode = "0400";
    };

    "postgres-authentik-password" = {
      owner = "postgres";
      group = "postgres";
      mode = "0400";
    };

    "postgres-netbird-password" = {
      owner = "postgres";
      group = "postgres";
      mode = "0400";
    };

    "postgres-cert-key" = {
      owner = "postgres";
      group = "postgres";
      mode = "0400";
    };

    "restic-env-file" = {};
    "restic-oci-repo" = {};
    "restic-encrypt-password" = {};
  };

  environment.etc."postgresql/server.crt".source = ./../files/certs/oci-db-server.publicsubnet.ocivcn.oraclevcn.com.crt;

  services = {
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      enableTCPIP = true;

      ensureDatabases = [
        "authentik"
        "netbird"
      ];

      ensureUsers = [
        {
          name = "authentik";
          ensureDBOwnership = true;
        }
        {
          name = "netbird";
          ensureDBOwnership = true;
        }
      ];

      settings = {
        ssl = "on";
        ssl_key_file = "${config.sops.secrets."postgres-cert-key".path}";
        ssl_cert_file = "/etc/postgresql/server.crt";
      };

      authentication = pkgs.lib.mkOverride 10 ''
        # PostgreSQL Client Authentication Configuration File
        # ===================================================
        # TYPE  DATABASE        USER            ADDRESS                 METHOD            OPTIONS
        # ------------------------------------------------------------------------------

        # 1. Local connections (Unix domain sockets)
        # Allow postgres only on Unix socket
        local   all             postgres                                peer

        # Allow other local users via password
        local   sameuser        all                                     scram-sha-256

        # 2. Localhost (IPv4 and IPv6)
        # Allow postgres to connect via localhost (loopback only)
        host    all             postgres        127.0.0.1/32            scram-sha-256
        host    all             postgres        ::1/128                 scram-sha-256

        # Allow all other users on localhost
        host    sameuser        all             127.0.0.1/32            scram-sha-256
        host    sameuser        all             ::1/128                 scram-sha-256

        # 3. Internal LAN
        # Explicitly deny postgres from the LAN or remote
        host    all             postgres        172.16.0.0/24           reject
        hostssl all             postgres        0.0.0.0/0               reject

        # Allow *only non-postgres* users from internal network
        host    sameuser        all             172.16.0.0/24           scram-sha-256

        # 4. Remote connections — SSL required (optional)
        # Allow *only non-postgres* users over SSL
        hostssl sameuser        all             0.0.0.0/0               scram-sha-256

        # ------------------------------------------------------------------------------
      '';
    };

    postgresqlBackup = {
      enable = true;

      databases = [
        "authentik"
        "netbird"
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

  systemd.services."postgresql-set-db-users" = {
    description = "Set postgres users, passwords and databases";
    # Make sure it runs *after* and *requires* PostgreSQL
    after = ["postgresql.service"];
    wants = ["postgresql.service"];
    # If PostgreSQL restarts, rerun this
    partOf = ["postgresql.service"];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = "${pkgs.writeShellScript "postgres-set-password" ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo "Waiting for PostgreSQL to be ready..."
        for i in {1..10}; do
          if ${pkgs.postgresql_16}/bin/pg_isready -U postgres > /dev/null 2>&1; then
            echo "PostgreSQL is ready!"
            break
          fi
          echo "Still waiting (\$i)..."
          sleep 2
        done


        echo "Setting password for postgres user..."
        ${pkgs.postgresql_16}/bin/psql -U postgres -d postgres -c "ALTER USER postgres PASSWORD '$(cat ${config.sops.secrets."postgres-password".path} | tr -d '\n')';"

        echo "Setting password for authentik user..."
        ${pkgs.postgresql_16}/bin/psql -U postgres -d postgres -c "ALTER USER authentik PASSWORD '$(cat ${config.sops.secrets."postgres-authentik-password".path} | tr -d '\n')';"

        echo "Setting password for netbird user..."
        ${pkgs.postgresql_16}/bin/psql -U postgres -d postgres -c "ALTER USER netbird PASSWORD '$(cat ${config.sops.secrets."postgres-netbird-password".path} | tr -d '\n')';"

        echo "User setup complete."
      ''}";
    };

    # Ensure it runs once on boot, and again if PostgreSQL is restarted
    wantedBy = ["postgresql.service" "multi-user.target"];
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/postgresql"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    5432
  ];
}
