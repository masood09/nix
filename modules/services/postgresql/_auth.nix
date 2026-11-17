# PostgreSQL auth — shared database/user definitions imported by machines.
{
  config,
  lib,
  ...
}: let
  pgPackage = config.services.postgresql.finalPackage;
  # LiteLLM (on mentat) reaches this instance over the tailnet. Its address
  # is the only one allowed to log in as litellm.
  litellmClient = "100.64.0.5/32";
in {
  config = {
    services = {
      postgresql = {
        ensureDatabases = [
          "applysmart"
          "litellm"
        ];

        ensureUsers = [
          {
            name = "applysmart";
            ensureDBOwnership = true;
          }
          {
            # LiteLLM's Prisma migrations create and alter tables, which
            # database ownership covers.
            name = "litellm";
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
          host    sameuser        babybuddy       10.0.0.0/8              scram-sha-256
          host    sameuser        mailarchiver    10.0.0.0/8              scram-sha-256

          # litellm from mentat's tailnet address only (deliberately narrower
          # than the applysmart range above)
          host    sameuser        litellm         ${litellmClient}          scram-sha-256

          # Hard-deny for everything else (good for least privilege)
          host    all             all             0.0.0.0/0               reject
          host    all             all             ::/0                    reject
        '';
      };

      postgresqlBackup = {
        databases = [
          "applysmart"
          "litellm"
        ];
      };
    };

    systemd = {
      services = {
        # Sets the litellm role's password from sops. ensureUsers creates the
        # role but cannot set a password, and every other password-auth role
        # here was given one by hand; this is the first that is declarative.
        # psql reads the file through \set with a backtick, so the password
        # never appears in argv, and :'pw' quotes it as a literal.
        postgresql-litellm-password = {
          description = "Set the litellm PostgreSQL role's password";
          wantedBy = [
            "multi-user.target"
          ];
          after = [
            "postgresql-setup.service"
          ];
          requires = [
            "postgresql-setup.service"
          ];
          path = [
            pgPackage
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "postgres";
            Group = "postgres";
          };
          script = ''
            psql -d postgres -X -q -v ON_ERROR_STOP=1 <<'SQL'
            \set pw `cat ${config.sops.secrets."litellm/db-password".path}`
            ALTER ROLE litellm WITH LOGIN PASSWORD :'pw';
            SQL
          '';
        };
      };
    };
  };
}
