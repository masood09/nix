{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  headscaleCfg = homelabCfg.services.headscale;
  cfg = headscaleCfg.headplane;
in {
  config = lib.mkIf (headscaleCfg.enable && cfg.enable) {
    homelab.zfs.datasets.headplane = lib.mkIf cfg.zfs.enable {
      inherit (cfg.zfs) dataset properties;

      enable = true;
      mountpoint = cfg.dataDir;
      requiredBy = ["headplane.service"];

      restic = {
        enable = true;
      };
    };

    services = {
      headplane = {
        enable = true;

        settings = {
          server = {
            host = "127.0.0.1";
            port = cfg.port;
            cookie_secret_path = config.sops.secrets."headscale/headplane/server_cookie.secret".path;
          };

          headscale = {
            url = "https://${headscaleCfg.webDomain}";
          };

          integration.agent = {
            enabled = true;
            pre_authkey_path = config.sops.secrets."headscale/headplane/integration_agent_pre_auth.key".path;
          };

          oidc = {
            issuer = headscaleCfg.oidc.issuer;
            client_id = headscaleCfg.oidc.clientId;
            client_secret_path = config.sops.secrets."headscale/oidc_client.secret".path;
            disable_api_key_login = true;
            headscale_api_key_path = config.sops.secrets."headscale/headplane/headscale_api.key".path;
            redirect_uri = "https://${headscaleCfg.webDomain}/admin/oidc/callback";
          };
        };
      };
    };

    systemd = {
      # Service ordering + mount requirements
      services = {
        headplane = lib.mkMerge [
          {
            unitConfig = {
              RequiresMountsFor = [
                (toString cfg.dataDir)
              ];
            };

            serviceConfig = {
              # stop systemd from trying to manage /var/lib/private + bind-mount behavior
              StateDirectory = lib.mkForce null;

              # with ProtectSystem=strict, you must explicitly allow writes here
              ReadWritePaths = [
                cfg.dataDir
              ];
            };
          }
          (lib.mkIf cfg.zfs.enable {
            requires = [
              "zfs-dataset-headplane.service"
            ];

            after = [
              "zfs-dataset-headplane.service"
            ];
          })
        ];

        headplane-permissions = {
          description = "Fix Headplane dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = ["headplane.service"];
          after =
            ["local-fs.target"]
            ++ lib.optionals cfg.zfs.enable [
              "zfs-dataset-headplane.service"
            ];
          requires = lib.optionals cfg.zfs.enable [
            "zfs-dataset-headplane.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown ${config.services.headscale.user}:${config.services.headscale.group} ${toString cfg.dataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        "d ${toString cfg.dataDir} 0700 ${config.services.headscale.user} ${config.services.headscale.group} -"
        "z ${toString cfg.dataDir} 0700 ${config.services.headscale.user} ${config.services.headscale.group} -"
      ];
    };
  };
}
