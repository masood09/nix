{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  services = {
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      enableTCPIP = true;

      ensureDatabases = [
        "babybuddy"
        "immich"
        "rxresume"
        "vaultwarden"
      ];

      ensureUsers = [
        {
          name = "babybuddy";
          ensureDBOwnership = true;
        }
        {
          name = "immich";
          ensureDBOwnership = true;
        }
        {
          name = "rxresume";
          ensureDBOwnership = true;
        }
        {
          name = "vaultwarden";
          ensureDBOwnership = true;
        }
      ];

      extensions = with pkgs.postgresql_16.pkgs; [pgvector vectorchord];
      settings.shared_preload_libraries = ["vchord.so"];

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
        host    all             postgres        0.0.0.0/0               reject
        hostssl all             postgres        0.0.0.0/0               reject

        # Allow *only non-postgres* users from internal network and Tailnet
        host    sameuser        all             10.0.20.0/24            scram-sha-256
        host    sameuser        all             100.64.0.0/16           scram-sha-256

        # 4. Remote connections — SSL required (optional)
        # Allow *only non-postgres* users over SSL
        hostssl sameuser        all             0.0.0.0/0               scram-sha-256

        # ------------------------------------------------------------------------------
      '';
    };

    postgresqlBackup = {
      enable = true;

      databases = [
        "babybuddy"
        "immich"
        "rxresume"
        "vaultwarden"
      ];

      pgdumpOptions = "--no-owner";
      startAt = "*-*-* *:15:00";
    };
  };

  networking.firewall.allowedTCPPorts = [5432];

  environment.persistence."/nix/persist" = lib.mkIf (!homelabCfg.isRootZFS) {
    directories = [
      "/var/lib/postgresql"
    ];
  };
}
