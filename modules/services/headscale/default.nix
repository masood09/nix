{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  headscaleCfg = homelabCfg.services.headscale;
  caddyEnabled = homelabCfg.services.caddy.enable;
in {
  imports = [
    ./dns.nix
    ./oidc.nix
    ./options.nix
  ];

  config = lib.mkIf headscaleCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.headscale = lib.mkIf headscaleCfg.zfs.enable {
      inherit (headscaleCfg.zfs) dataset properties;

      enable = true;
      mountpoint = headscaleCfg.dataDir;
      requiredBy = ["headscale.service"];

      restic = {
        enable = true;
      };
    };

    services = {
      headscale = {
        inherit (headscaleCfg) enable;

        settings = {
          logtail.enabled = false;
          server_url = "https://${headscaleCfg.webDomain}";
          metrics_listen_addr = "127.0.0.1:${toString headscaleCfg.metricsPort}";
          policy.path = config.sops.secrets."headscale-acl.hujson".path;
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${headscaleCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.headscale.port}
            '';
          };
        };
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services.headscale = lib.mkMerge [
        {
          # Unit-level ordering / mount requirements
          unitConfig = {
            RequiresMountsFor = [headscaleCfg.dataDir];
          };
        }

        (lib.mkIf headscaleCfg.zfs.enable {
          requires = ["zfs-dataset-headscale.service"];
          after = ["zfs-dataset-headscale.service"];
        })
      ];

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${headscaleCfg.dataDir} 0750 headscale headscale -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !headscaleCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          headscaleCfg.dataDir
        ];
      };
  };
}
