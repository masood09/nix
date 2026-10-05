# Aurral — music discovery and playlist manager for the shared Lidarr library.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.aurral;
  caddyEnabled = homelabCfg.services.caddy.enable;
  oidcClientSecret = config.sops.secrets."aurral/oidc-client-secret".path;

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "aurral";
    inherit (cfg) dataDir;
    user = "aurral";
    group = "aurral";
    mainServices = ["aurral"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-aurral";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    homelab = {
      zfs = {
        datasets = {
          aurral = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = cfg.dataDir;
            requiredBy = ["aurral.service"];

            restic = {
              enable = cfg.zfs.restic.enable;
            };
          };
        };
      };
    };

    users = {
      users = {
        aurral = {
          isSystemUser = true;
          group = "aurral";
          extraGroups = ["media"];
          uid = cfg.userId;
        };
      };

      groups = {
        aurral = {
          gid = cfg.groupId;
        };
      };
    };

    systemd = lib.mkMerge [
      permSvc.systemd
      {
        services = {
          aurral = {
            description = "Aurral music discovery and playlist manager";
            wantedBy = ["multi-user.target"];
            after = ["network-online.target"];
            wants = ["network-online.target"];
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir cfg.mediaDir];
            };
            serviceConfig = {
              ExecStart = pkgs.writeShellScript "aurral-start" ''
                if [ "${lib.boolToString cfg.oidc.enable}" = true ]; then
                  export OIDC_CLIENT_SECRET="$(cat ${lib.escapeShellArg oidcClientSecret})"
                fi
                exec ${pkgs.aurral}/bin/aurral
              '';
              Restart = "on-failure";
              User = "aurral";
              Group = "aurral";
              SupplementaryGroups = ["media"];
              ReadWritePaths = [cfg.dataDir cfg.mediaDir];
            };
            environment = {
              AURRAL_DATA_DIR = cfg.dataDir;
              DOWNLOAD_FOLDER = "${cfg.mediaDir}/downloads/aurral";
              FILE_BROWSE_ROOTS = cfg.mediaDir;
              PORT = toString cfg.listenPort;
              TRUST_PROXY = cfg.listenAddress;
              AURRAL_PUBLIC_URL = "https://${cfg.webDomain}";
              OIDC_ENABLED = lib.boolToString cfg.oidc.enable;
              OIDC_ISSUER = lib.mkIf cfg.oidc.enable cfg.oidc.issuer;
              OIDC_CLIENT_ID = lib.mkIf cfg.oidc.enable cfg.oidc.clientId;
              OIDC_REDIRECT_URI = lib.mkIf cfg.oidc.enable "https://${cfg.webDomain}/sso/callback";
              OIDC_SCOPES = lib.mkIf cfg.oidc.enable "openid profile email";
              OIDC_USERNAME_CLAIM = lib.mkIf cfg.oidc.enable "email";
              OIDC_ADMIN_USERS = lib.mkIf cfg.oidc.enable (lib.concatStringsSep "," cfg.oidc.adminUsers);
              OIDC_DOMAIN = lib.mkIf cfg.oidc.enable "https://${config.networking.domain}";
            };
          };
        };
      }
    ];

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = cfg.zfs.enable;
      directories = [cfg.dataDir];
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://${cfg.listenAddress}:${toString cfg.listenPort}
            '';
          };
        };
      };
    };
  };
}
