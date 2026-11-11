# Options — Actual Budget personal finance server (domain, port, OIDC, ZFS).
{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        actual = {
          enable = lib.mkEnableOption "Actual Budget personal finance server.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "budget.${config.networking.domain}";
            description = "Public hostname for Actual Budget.";
          };

          dataDir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/actual";
            description = "Directory holding Actual's server-files (account.sqlite) and user-files (budget blobs). Upstream warns that changing this after first start can break the instance.";
          };

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address on which Actual listens behind Caddy.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8919;
            description = "Port on which Actual listens.";
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3019;
            description = "UID for the Actual service user.";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3019;
            description = "GID for the Actual service group.";
          };

          sessionLifetime = lib.mkOption {
            type = lib.types.ints.positive;
            default = 7 * 24 * 60 * 60;
            description = ''
              Lifetime of an Actual login session, in seconds (token_expiration).
              This bounds how long someone removed from the Authentik
              application, or disabled upstream, keeps access through an
              existing session. Disabling the user in Actual's User Directory
              ends it immediately.

              Upstream reads the same value with different units: OpenID
              sessions use seconds, but loginWithPassword (accounts/password.js,
              still in 26.11) multiplies it by 60, i.e. minutes. A password
              session therefore lives ~60x longer (the 7-day default becomes
              ~420 days). Applied unconditionally, so it also replaces
              upstream's "never" on password-only instances.
            '';
          };

          oidc = {
            enable = lib.mkEnableOption ''
              OpenID-only login for Actual via Authentik (password login is
              disallowed). Requires an `actualbudget/oidc/client-secret` key in the
              host's secrets.sops.yaml, declared in its _secrets.nix with
              `owner = "actual"` (upstream's preStart reads it as that user)
              and `restartUnits = ["actual.service"]`'';

            discoveryUrl = lib.mkOption {
              type = lib.types.str;
              default = "https://auth.${config.networking.domain}/application/o/actualbudget/";
              description = "OpenID provider discovery URL.";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "actualbudget";
              description = "OpenID client ID for Actual.";
            };

            userCreationMode = lib.mkOption {
              type = lib.types.enum ["manual" "login"];
              default = "manual";
              description = ''
                Actual's userCreationMode. "login" creates a BASIC user on first
                OpenID login, so the Authentik application's bindings decide who
                can get an account (at login time; see sessionLifetime for
                existing sessions). "manual" (upstream default) requires an
                admin to pre-create each user in Actual's User Directory with
                the username Authentik returns as preferred_username, i.e. the
                Authentik username, not the email. The first login becomes the
                owner/admin in both modes.
              '';
            };
          };

          zfs = zfsOpts {
            serviceName = "Actual Budget";
            dataset = "dpool/tank/services/actual";
            properties = {
              logbias = "latency";
              recordsize = "16K";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
