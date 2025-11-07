{config, ...}: {
  sops.secrets = {
    "lldap-env" = {
      owner = "lldap";
      sopsFile = ./../../../secrets/oci-ldap-server.yaml;
    };
    "lldap-jwt-secret" = {
      owner = "lldap";
      sopsFile = ./../../../secrets/oci-ldap-server.yaml;
    };
    "lldap-user-pass" = {
      owner = "lldap";
      sopsFile = ./../../../secrets/oci-ldap-server.yaml;
    };

    "restic-env" = {
      sopsFile = ./../../../secrets/oci-ldap-server.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../../secrets/oci-ldap-server.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../../secrets/oci-ldap-server.yaml;
    };
  };

  services = {
    lldap = {
      enable = true;
      environmentFile = config.sops.secrets."lldap-env".path;

      settings = {
        database_url = "postgresql:///lldap?host=/run/postgresql";
        force_ldap_user_pass_reset = "always";
        http_host = "127.0.0.1";
        http_url = "https://ldap.mantannest.com";
        jwt_secret_file = config.sops.secrets."lldap-jwt-secret".path;
        ldap_base_dn = "dc=mantannest,dc=com";
        ldap_host = "0.0.0.0";
        ldap_user_dn = "admin";
        ldap_user_email = "admin@ahmedmasood.com";
        ldap_user_pass_file = config.sops.secrets."lldap-user-pass".path;
      };
    };

    postgresql = {
      ensureDatabases = [
        "lldap"
      ];

      ensureUsers = [
        {
          name = "lldap";
          ensureDBOwnership = true;
        }
      ];
    };

    postgresqlBackup = {
      databases = ["lldap"];
    };

    restic.backups.localBackup = {
      initialize = true;
      environmentFile = config.sops.secrets."restic-env".path;
      repositoryFile = config.sops.secrets."restic-repo".path;
      passwordFile = config.sops.secrets."restic-password".path;

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

  users.groups.lldap = {};

  users.users.lldap = {
    name = "lldap";
    group = "lldap";
    description = "lldap server user";
    isSystemUser = true;
  };

  networking.firewall.allowedTCPPorts = [
    config.services.lldap.settings.ldap_port
  ];
}
