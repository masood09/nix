# Actual Budget — local-first personal finance app (sync server + web UI).
# Wraps the upstream nixpkgs `services.actual` module with a static user,
# an optional ZFS dataset, and a Caddy vhost. Password login by default;
# `oidc.enable` switches to Authentik-only (OpenID) login.
#
# Actual validates its config strictly (convict `allowed: "strict"`), so any
# key added to `settings` must exist in upstream's schema
# (packages/sync-server/src/load-config.js) or the server refuses to start,
# even though the nixpkgs module's freeformType accepts anything.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.actual;
  caddyEnabled = config.services.caddy.enable;

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "actual";
    inherit (cfg) dataDir;
    user = "actual";
    group = "actual";
    mainServices = ["actual"];
    # Upstream lists these in ReadWritePaths but Actual never creates them.
    subDirectories = [
      config.services.actual.settings.serverFiles
      config.services.actual.settings.userFiles
    ];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-actual";
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
          actual = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = cfg.dataDir;
            requiredBy = ["actual.service"];

            restic = {
              inherit (cfg.zfs.restic) enable;
            };
          };
        };
      };
    };

    services = {
      actual = {
        enable = true;
        # Static user instead of upstream's DynamicUser so the UID stays
        # stable across ZFS snapshot and restic restores.
        user = "actual";
        group = "actual";

        settings =
          {
            hostname = cfg.listenAddress;
            port = cfg.listenPort;
            inherit (cfg) dataDir;
            # Caddy connects over loopback, which upstream's default
            # trustedProxies (RFC1918 + ::1) does not include.
            trustedProxies = [
              "127.0.0.1/32"
              "::1/128"
            ];
            # Upstream's default is "never", so a session would outlive any
            # Authentik-side revocation. "openid-provider" is no better: it
            # copies Authentik's 10-minute access-token lifetime.
            token_expiration = cfg.sessionLifetime;
            # allowedLoginMethods only filters the method a client asks for;
            # otherwise Actual uses the instance's active auth row. With OIDC
            # on, startup re-bootstraps OpenID and marks every other row
            # inactive, so password stays unusable unless an admin re-enables
            # it in the UI (and then only until the next restart).
            # enforceOpenId hides the other methods from the login page.
            # Header auth is never used.
            allowedLoginMethods =
              if cfg.oidc.enable
              then ["openid"]
              else ["password"];
          }
          // lib.optionalAttrs cfg.oidc.enable {
            loginMethod = "openid";
            enforceOpenId = true;
            inherit (cfg.oidc) userCreationMode;
            openId = {
              discoveryURL = cfg.oidc.discoveryUrl;
              client_id = cfg.oidc.clientId;
              client_secret = {
                _secret = config.sops.secrets."actualbudget/oidc/client-secret".path;
              };
              server_hostname = "https://${cfg.webDomain}";
              authMethod = "openid";
            };
          };
      };

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

    users = {
      users = {
        actual = {
          isSystemUser = true;
          group = "actual";
          uid = cfg.userId;
        };
      };

      groups = {
        actual = {
          gid = cfg.groupId;
        };
      };
    };

    inherit (permSvc) systemd;

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = cfg.zfs.enable;
      directories = [cfg.dataDir];
    };
  };
}
