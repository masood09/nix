{
  imports = [
    ./../../../services/_postgresql.nix
  ];

  services = {
    postgresql = {
      ensureDatabases = [
        "authelia-mantannest"
      ];

      ensureUsers = [
        {
          name = "authelia-mantannest";
          ensureDBOwnership = true;
        }
      ];
    };

    postgresqlBackup = {
      databases = [
        "authelia-mantannest"
        "authentik"
      ];
    };
  };
}
