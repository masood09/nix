{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.matrix-authentication-service;
  format = pkgs.formats.yaml {};

  name = "matrix-authentication-service";

  # remove null values from the final configuration
  finalSettings = lib.filterAttrsRecursive (_: v: v != null) cfg.settings;
  configFile = format.generate "matrix-authentication-service.yaml" finalSettings;

  configArgs =
    lib.concatMapStringsSep " " (x: "--config ${x}")
    ([configFile] ++ cfg.extraConfigFiles);

  inherit
    (lib)
    types
    mkIf
    mkOption
    mkEnableOption
    ;
in {
  options.services.matrix-authentication-service = {
    enable = mkEnableOption "Enable Matrix Authentication Service (MAS)";

    package = lib.mkPackageOption pkgs "matrix-authentication-service" {};

    settings = mkOption {
      default = {};

      type = types.submodule {
        freeformType = format.type;
        options = {
          database = {
            host = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Hostname or IP address of the PostgreSQL server.

                Set this when connecting over TCP. If `null`, a Unix domain socket
                connection will be used via `socket`.
              '';
            };

            port = mkOption {
              type = types.port;
              default = 5432;
              description = ''
                TCP port of the PostgreSQL server.

                Only used when `host` is set (TCP connections).
              '';
            };

            socket = mkOption {
              type = types.nullOr types.str;
              default = "/run/postgresql";
              description = ''
                Path to the PostgreSQL Unix domain socket directory.

                Used when `host` is `null`. Set to `null` to disable socket usage
                and require TCP configuration via `host`.
              '';
            };

            username = mkOption {
              type = types.str;
              default = name;
              description = ''
                PostgreSQL username used by Matrix Authentication Service.
              '';
            };

            password = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                PostgreSQL password for the configured user.

                It is recommended to provide this via a secret file using
                `extraConfigFiles` rather than setting it directly.
              '';
            };

            database = mkOption {
              type = types.str;
              default = name;
              description = ''
                Name of the PostgreSQL database used by Matrix Authentication Service.
              '';
            };
          };

          email = {
            from = mkOption {
              type = types.str;
              default = "\"Authentication Service\" <root@localhost>";
              description = ''
                Sender address used for outgoing emails.

                This value is used as the `From:` header in emails sent by
                Matrix Authentication Service.
              '';
            };

            reply_to = mkOption {
              type = types.str;
              default = "\"Authentication Service\" <root@localhost>";
              description = ''
                Reply-To address used for outgoing emails.

                Clients replying to MAS-generated emails will send responses
                to this address.
              '';
            };

            transport = mkOption {
              type = types.str;
              default = "blackhole";
              description = ''
                Email transport backend to use.

                The default value "blackhole" disables actual email delivery
                and discards outgoing messages. Configure a proper SMTP
                transport for production use.
              '';
            };
          };

          http = {
            trusted_proxies = mkOption {
              type = types.listOf types.str;
              default = [
                "192.168.0.0/16"
                "172.16.0.0/12"
                "10.0.0.0/10"
                "127.0.0.1/8"
                "fd00::/8"
                "::1/128"
              ];
              description = ''
                List of CIDR ranges considered trusted reverse proxies.

                Requests originating from these networks may have forwarded
                headers (such as `X-Forwarded-For`) honored by MAS.

                Adjust this when running MAS behind a reverse proxy.
              '';
            };

            public_base = mkOption {
              type = types.str;
              default = "http://[::]:8080/";
              description = ''
                Public base URL of the Matrix Authentication Service.

                This must match the externally accessible URL used by clients
                and OIDC flows, including scheme and trailing slash.
              '';
            };
          };

          matrix = {
            kind = mkOption {
              type = types.str;
              default = "synapse";
              description = ''
                Matrix homeserver implementation to integrate with.

                For Synapse, set this to "synapse".
              '';
            };

            homeserver = mkOption {
              type = types.str;
              default = "localhost:8008";
              description = ''
                The homeserver address (server name) MAS should use.

                For Synapse this typically matches the homeserver's client/server name,
                often expressed as host:port (e.g. "localhost:8008").
              '';
            };

            secret_file = mkOption {
              type = types.path;
              default = "";
              description = ''
                Shared secret used by MAS to authenticate to the homeserver admin API.

                It is recommended to provide this via a secret file using sops secret.
              '';
            };

            endpoint = mkOption {
              type = types.str;
              default = "http://localhost:8008/";
              description = ''
                Base URL where the homeserver is reachable from MAS.

                For Synapse this is typically the internal URL to the homeserver,
                such as "http://localhost:8008/".
              '';
            };
          };

          passwords = {
            enabled = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether to enable the local password database.

                If disabled, users will only be able to authenticate using
                upstream OIDC providers.
              '';
            };

            minimum_complexity = mkOption {
              type = types.ints.between 0 4;
              default = 3;
              description = ''
                Minimum password complexity required, as estimated by the
                zxcvbn algorithm.

                Must be between 0 (very weak) and 4 (very strong).

                See https://github.com/dropbox/zxcvbn#usage for details
                on how complexity is calculated.
              '';
            };

            schemes = mkOption {
              type = types.listOf (types.submodule {
                freeformType = format.type;

                options = {
                  version = mkOption {
                    type = types.ints.unsigned;
                    description = ''
                      Version identifier for the password hashing scheme.

                      This is used internally by MAS to determine which
                      hashing configuration applies to stored passwords.
                    '';
                  };

                  algorithm = mkOption {
                    type = types.str;
                    description = ''
                      Password hashing algorithm to use.

                      The default and recommended value is "argon2id".
                      Only change this if you fully understand the
                      implications for password storage and migration.
                    '';
                  };
                };
              });

              default = [
                {
                  version = 1;
                  algorithm = "argon2id";
                }
              ];

              description = ''
                List of password hashing schemes in use.

                ⚠ Only modify this if you understand how MAS handles
                password hashing and migration between versions.
              '';
            };
          };
        };
      };

      description = "Matrix Authentication Service configuration, see <https://element-hq.github.io/matrix-authentication-service/reference/configuration.html> for reference.";
    };

    extraConfigFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      description = ''
        Extra config files passed via `--config`.

        Use this for secrets (e.g. a sops-nix rendered YAML under /run/secrets),
        so secrets don't get written into the Nix store.
      '';
    };
  };

  config = mkIf cfg.enable {
    users = {
      users."${name}" = {
        isSystemUser = true;
        group = name;
      };

      groups.matrix-authentication-service = {};
    };

    systemd.services.matrix-authentication-service = {
      description = "Matrix Authentication Service (MAS)";
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        User = name;
        Group = name;

        ExecStartPre = [
          ("+"
            + (pkgs.writeShellScript "mas-check-config" ''
              ${lib.getExe cfg.package} config check ${configArgs}
            ''))
        ];

        ExecStart = "${lib.getExe cfg.package} server ${configArgs}";

        Restart = "on-failure";
        RestartSec = "1s";
      };
    };
  };
}
