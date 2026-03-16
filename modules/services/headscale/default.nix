{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  headscaleCfg = homelabCfg.services.headscale;
  caddyEnabled = homelabCfg.services.caddy.enable;

  dataDir = lib.removeSuffix "/" (toString headscaleCfg.dataDir);

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "headscale";
    inherit dataDir;
    user = "headscale";
    group = "headscale";
    mode = "0750";
    mainServices = ["headscale"];
    zfs = {
      enable = headscaleCfg.zfs.enable;
      datasetServiceName = "zfs-dataset-headscale";
    };
  };
in {
  imports = [
    ./alloy.nix
    ./headplane.nix
    ./oidc.nix
    ./options.nix
  ];

  config = lib.mkIf headscaleCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.headscale = lib.mkIf headscaleCfg.zfs.enable {
      inherit (headscaleCfg.zfs) dataset properties;

      enable = true;
      mountpoint = dataDir;
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

          log = {
            level = "info";
            format = "json";
          };

          dns = {
            override_local_dns = true;
            extra_records_path = config.sops.secrets."headscale/dns-extra-records.json".path;

            base_domain = "dns.${headscaleCfg.webDomain}";

            nameservers = {
              global = [
                "100.64.0.17"
                "100.64.0.22"
              ];
            };
          };

          policy = {
            mode = "database";
          };
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${headscaleCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              ${lib.optionalString headscaleCfg.headplane.enable ''
                # Headplane admin UI
                @headplane path /admin /admin/*
                  reverse_proxy @headplane http://127.0.0.1:${toString headscaleCfg.headplane.port}
              ''}

              # Headscale main API/UI (everything else)
              reverse_proxy http://127.0.0.1:${toString config.services.headscale.port}
            '';
          };
        };
      };
    };

    inherit (permSvc) systemd;

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !headscaleCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          dataDir
        ];
      };
  };
}
