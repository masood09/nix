{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.mailarchiver;

  # This generates JSON *text* we can safely write into a runtime file
  settingsJson = builtins.toJSON cfg.settings;

  settingsFile = pkgs.writeText "mailarchiver-appsettings.json" settingsJson;
in {
  options.services.mailarchiver = {
    enable = lib.mkEnableOption "MailArchiver";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.mailarchiver;
      description = "MailArchiver package to run.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/mailarchiver";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
    };

    port = lib.mkOption {
      default = 5000;
      type = lib.types.port;
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      default = [];
      example = [
        "/run/secrets/mailarchiver.env"
      ];
      description = ''
        Files containing environment variables (KEY=VALUE per line)
        loaded by systemd before starting MailArchiver.

        Use this file to store any credentials that have to be declared,
        instead of declaring under settings.
      '';
    };

    environment = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Additional environment variables passed to the MailArchiver service.
        Each entry must be in KEY=VALUE format.
      '';
    };

    settings = lib.mkOption {
      description = "MailArchiver appsettings.json structure (deep-mergeable).";
      type = lib.types.submodule ({lib, ...}: {
        freeformType = lib.types.attrsOf lib.types.anything;

        options = {
          ConnectionStrings = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                DefaultConnection = lib.mkOption {
                  type = lib.types.str;
                  default = "Host=/run/postgresql;Database=mailarchiver;Username=mailarchiver;";
                };
              };
            };
          };

          DataProtection = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                KeyPath = lib.mkOption {
                  type = lib.types.path;
                  default = "${cfg.dataDir}/DataProtection-Keys";
                };
              };
            };
          };

          Authentication = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                Username = lib.mkOption {
                  type = lib.types.str;
                  default = "admin";
                };

                Password = lib.mkOption {
                  type = lib.types.str;
                  default = "secure123!";
                };

                SessionTimeoutMinutes = lib.mkOption {
                  type = lib.types.int;
                  default = 60;
                };

                CookieName = lib.mkOption {
                  type = lib.types.str;
                  default = "MailArchiverAuth";
                };
              };
            };
          };

          OAuth = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                Enabled = lib.mkEnableOption "Enable OAuth";

                Authority = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                };

                ClientId = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                };

                ClientSecret = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                };

                ClientScopes = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = ["openid" "profile" "email"];
                };

                DisablePasswordLogin = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };

                AutoRedirect = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };

                AutoApproveUsers = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };

                AdminEmails = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [];
                };
              };
            };
          };

          MailSync = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                IntervalMinutes = lib.mkOption {
                  type = lib.types.int;
                  default = 15;
                };

                TimeoutMinutes = lib.mkOption {
                  type = lib.types.int;
                  default = 120;
                };

                ConnectionTimeoutSeconds = lib.mkOption {
                  type = lib.types.int;
                  default = 300;
                };

                CommandTimeoutSeconds = lib.mkOption {
                  type = lib.types.int;
                  default = 600;
                };

                AlwaysForceFullSync = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };

                IgnoreSelfSignedCert = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
              };
            };
          };

          BatchRestore = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                AsyncThreshold = lib.mkOption {
                  type = lib.types.int;
                  default = 50;
                };

                MaxSyncEmails = lib.mkOption {
                  type = lib.types.int;
                  default = 150;
                };

                MaxAsyncEmails = lib.mkOption {
                  type = lib.types.int;
                  default = 50000;
                };

                SessionTimeoutMinutes = lib.mkOption {
                  type = lib.types.int;
                  default = 30;
                };

                DefaultBatchSize = lib.mkOption {
                  type = lib.types.int;
                  default = 50;
                };
              };
            };
          };

          Selection = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                MaxSelectableEmails = lib.mkOption {
                  type = lib.types.int;
                  default = 250;
                };
              };
            };
          };

          View = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                DefaultToPlainText = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };

                BlockExternalResources = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
              };
            };
          };

          BatchOperation = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                BatchSize = lib.mkOption {
                  type = lib.types.int;
                  default = 50;
                };

                PauseBetweenEmailsMs = lib.mkOption {
                  type = lib.types.int;
                  default = 50;
                };

                PauseBetweenBatchesMs = lib.mkOption {
                  type = lib.types.int;
                  default = 200;
                };
              };
            };
          };

          TimeZone = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                DisplayTimeZoneId = lib.mkOption {
                  type = lib.types.str;
                  default = "Etc/UTC";
                };
              };
            };
          };

          DatabaseMaintenance = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                Enabled = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };

                DailyExecutionTime = lib.mkOption {
                  type = lib.types.str;
                  default = "02:00";
                };

                TimeoutMinutes = lib.mkOption {
                  type = lib.types.int;
                  default = 30;
                };
              };
            };
          };

          Upload = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                MaxFileSizeGB = lib.mkOption {
                  type = lib.types.int;
                  default = 10;
                };

                KeepAliveTimeoutHours = lib.mkOption {
                  type = lib.types.int;
                  default = 4;
                };

                RequestHeadersTimeoutHours = lib.mkOption {
                  type = lib.types.int;
                  default = 2;
                };

                Notes = lib.mkOption {
                  type = lib.types.str;
                  default = "Optimized for large file uploads up to 10GB";
                };
              };
            };
          };

          Npgsql = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                CommandTimeout = lib.mkOption {
                  type = lib.types.int;
                  default = 900;
                };
              };
            };
          };

          Logging = lib.mkOption {
            default = {};
            type = lib.types.submodule {
              options = {
                LogLevel = lib.mkOption {
                  # arbitrary key -> string
                  type = lib.types.attrsOf lib.types.str;
                  default = {
                    Default = "Information";
                    "Microsoft.AspNetCore" = "Warning";
                    "Microsoft.EntityFrameworkCore.Database.Command" = "Warning";
                  };
                };
              };
            };
          };

          AllowedHosts = lib.mkOption {
            type = lib.types.str;
            default = "*";
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.mailarchiver = {
        isSystemUser = true;
        group = "mailarchiver";
      };

      groups.mailarchiver = {};
    };

    systemd = {
      services.mailarchiver = {
        description = "MailArchiver";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];

        serviceConfig = {
          User = "mailarchiver";
          Group = "mailarchiver";
          StateDirectory = "mailarchiver";
          WorkingDirectory = cfg.dataDir;

          # Write config right before start (copy from store -> state dir)
          ExecStartPre = [
            "${pkgs.coreutils}/bin/install -m 0600 -o mailarchiver -g mailarchiver ${settingsFile} /var/lib/mailarchiver/appsettings.json"
            "${pkgs.coreutils}/bin/mkdir -p ${cfg.settings.DataProtection.KeyPath}"
            "${pkgs.coreutils}/bin/rm -rf ${cfg.dataDir}/wwwroot"
            "${pkgs.coreutils}/bin/ln -s ${cfg.package}/lib/mail-archiver/wwwroot ${cfg.dataDir}/wwwroot"
            "${pkgs.coreutils}/bin/chown -R mailarchiver:mailarchiver ${cfg.dataDir}"
          ];

          ExecStart = "${cfg.package}/bin/MailArchiver --contentRoot ${cfg.dataDir}";

          Restart = "always";
          RestartSec = 5;

          Environment =
            [
              "ASPNETCORE_ENVIRONMENT=Production"
              "ASPNETCORE_URLS=http://${cfg.listenAddress}:${toString cfg.port}"
            ]
            ++ cfg.environment;

          EnvironmentFile = cfg.environmentFile;
        };
      };
    };
  };
}
