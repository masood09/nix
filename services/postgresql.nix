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
  };

  systemd.services.postgresql.serviceConfig = {
    EnvironmentFile = config.sops.secrets."postgres-password".path;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      # PostgreSQL Client Authentication Configuration File
      # ===================================================
      # TYPE  DATABASE        USER            ADDRESS                 METHOD            OPTIONS
      # ------------------------------------------------------------------------------

      # 1. Local connections (Unix domain sockets)
      # Allow postgres only on Unix socket
      local   all             postgres                                peer

      # Allow other local users via password
      local   all             all                                     md5

      # 2. Localhost (IPv4 and IPv6)
      # Allow postgres to connect via localhost (loopback only)
      host    all             postgres        127.0.0.1/32            md5
      host    all             postgres        ::1/128                 md5

      # Allow all other users on localhost
      host    all             all             127.0.0.1/32            md5
      host    all             all             ::1/128                 md5

      # 3. Internal LAN
      # Allow *only non-postgres* users from internal network
      host    all             all             172.16.0.0/24           md5

      # 4. Remote connections — SSL required (optional)
      # Allow *only non-postgres* users over SSL
      hostssl all             all             172.16.0.0/24           scram-sha-256

      # ------------------------------------------------------------------------------

      # Explicitly deny postgres from the LAN or remote
      # (Placed at the end; order matters — first match wins)
      host    all             postgres        172.16.0.0/24           reject
      hostssl all             postgres        0.0.0.0/0               reject
    '';
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
        echo "Password updated successfully."
      ''}";
    };

    # Ensure it runs once on boot, and again if PostgreSQL is restarted
    wantedBy = ["postgresql.service" "multi-user.target"];
  };

  # Run the service on every nixos-rebuild
  system.activationScripts.postgresqlSetDbUsers = {
    text = ''
      echo "Triggering postgresql-set-db-users after rebuild..."
      ${pkgs.systemd}/bin/systemctl start postgresql-set-db-users || true
    '';
  };
}
