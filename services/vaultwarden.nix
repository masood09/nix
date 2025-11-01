{config, ...}: {
  imports = [
    ./acme.nix
    ./_nginx.nix
    ./_postgresql.nix
  ];

  sops.secrets = {
    "vaultwarden-environment-file" = {
      owner = "vaultwarden";
      sopsFile = ./../secrets/vaultwarden-env;
      format = "binary";
    };
  };

  services = {
    vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      environmentFile = config.sops.secrets."vaultwarden-environment-file".path;

      config = {
        DOMAIN = "https://passwords.mantannest.com";
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
      };
    };

    postgresql = {
      ensureDatabases = ["vaultwarden"];
      ensureUsers = [
        {
          name = "vaultwarden";
          ensureDBOwnership = true;
        }
      ];
    };

    postgresqlBackup = {
      databases = ["vaultwarden"];
    };

    nginx.virtualHosts."passwords.mantannest.com" = {
      forceSSL = true;
      useACMEHost = "mantannest.com";
      locations."/" = {
        proxyPass = "http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      };
    };
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/vaultwarden"
    ];
  };
}
