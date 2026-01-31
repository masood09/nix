{lib, ...}: {
  config = {
    services = {
      postgresql = {
        ensureDatabases = [
          "applysmart"
        ];

        ensureUsers = [
          {
            name = "applysmart";
            ensureDBOwnership = true;
          }
        ];

        authentication = lib.mkAfter ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD

          # babybuddy + applysmart via TCP/IP (password), ONLY to DB with same name as user
          host    sameuser        babybuddy       127.0.0.1/32            scram-sha-256
          host    sameuser        applysmart      127.0.0.1/32            scram-sha-256
          host    sameuser        babybuddy       ::1/128                 scram-sha-256
          host    sameuser        applysmart      ::1/128                 scram-sha-256

          # babybuddy + applysmart via LAN/Tailnet (password), but ONLY to DB with same name as user
          host    sameuser        applysmart      10.0.20.0/24            scram-sha-256
          host    sameuser        applysmart      100.64.0.0/16           scram-sha-256
          host    sameuser        babybuddy       10.88.0.0/16            scram-sha-256

          # Hard-deny for everything else (good for least privilege)
          host    all             all             0.0.0.0/0               reject
          host    all             all             ::/0                    reject
        '';
      };

      postgresqlBackup = {
        databases = [
          "applysmart"
        ];
      };
    };
  };
}
