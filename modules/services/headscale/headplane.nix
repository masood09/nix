{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  headscaleCfg = homelabCfg.services.headscale;
  cfg = headscaleCfg.headplane;

  format = pkgs.formats.yaml {};

  # A workaround generate a valid Headscale config accepted by Headplane when `config_strict == true`.
  settings = lib.recursiveUpdate config.services.headscale.settings {
    tls_cert_path = "/dev/null";
    tls_key_path = "/dev/null";
    policy.path = "/dev/null";
  };

  headscaleConfig = format.generate "headscale.yml" settings;
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
            inherit (cfg) port;

            host = "127.0.0.1";
            cookie_secret_path = config.sops.secrets."headscale/headplane/server-cookie-secret".path;
          };

          headscale = {
            url = "https://${headscaleCfg.webDomain}";
            config_path = "${headscaleConfig}";
            dns_records_path = config.services.headscale.settings.dns.extra_records_path;
          };

          integration.agent = {
            enabled = true;
            pre_authkey_path = config.sops.secrets."headscale/headplane/integration-agent-pre-auth-key".path;
          };

          oidc = {
            inherit (headscaleCfg.oidc) issuer;

            client_id = headscaleCfg.oidc.clientId;
            client_secret_path = config.sops.secrets."headscale/oidc-client-secret".path;
            disable_api_key_login = true;
            headscale_api_key_path = config.sops.secrets."headscale/headplane/headscale-api-key".path;
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
