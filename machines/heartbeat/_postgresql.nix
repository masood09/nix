{
  pkgs,
  ...
}: {
  config = {
    services = {
      postgresql = {
        ensureDatabases = [
          "applysmart"
          "babybuddy"
        ];

        ensureUsers = [
          {
            name = "applysmart";
            ensureDBOwnership = true;
          }
          {
            name = "babybuddy";
            ensureDBOwnership = true;
          }
        ];

        authentication = pkgs.lib.mkOverride 10 ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD

          # postgres can connect ONLY via Unix socket
          local   all             postgres                                peer
          host    all             postgres        127.0.0.1/32            reject
          host    all             postgres        ::1/128                 reject
          host    all             postgres        0.0.0.0/0               reject

          # Other local users via Unix socket (no password), but ONLY to DB with same name as user
          local   sameuser        all                                     peer

          # babybuddy + applysmart via TCP/IP (password), ONLY to DB with same name as user
          host    sameuser        babybuddy       127.0.0.1/32            scram-sha-256
          host    sameuser        applysmart      127.0.0.1/32            scram-sha-256
          host    sameuser        babybuddy       ::1/128                 scram-sha-256
          host    sameuser        applysmart      ::1/128                 scram-sha-256

          # babybuddy + applysmart via LAN/Tailnet (password), but ONLY to DB with same name as user
          host    sameuser        babybuddy       10.0.20.0/24            scram-sha-256
          host    sameuser        applysmart      10.0.20.0/24            scram-sha-256
          host    sameuser        babybuddy       100.64.0.0/16           scram-sha-256
          host    sameuser        applysmart      100.64.0.0/16           scram-sha-256

          # Hard-deny for everything else (good for least privilege)
          host    all             all             0.0.0.0/0               reject
          host    all             all             ::/0                    reject
        '';
      };

      postgresqlBackup = {
        databases = [
          "applysmart"
          "babybuddy"
        ];
      };
    };
  };
}
