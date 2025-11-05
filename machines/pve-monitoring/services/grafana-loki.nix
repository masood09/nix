{ config, ... }: {
  sops.secrets = {
    "loki-env" = {
      owner = "loki";
      sopsFile = ./../../../secrets/pve-monitoring.yaml;
    };
  };

  services = {
    loki = {
      enable = true;

      extraFlags = [
        "-config.expand-env=true"
      ];

      configuration = {
        auth_enabled = false;

        server = {
          http_listen_address = "127.0.0.1";
        };

        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };

          replication_factor = 1;
          path_prefix = "/var/lib/loki";
        };

        schema_config = {
          configs = [
            {
              from = "2025-11-05";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";

              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/index";
            cache_location = "/var/lib/loki/index_cache";
          };

          aws = {
            s3 = "\${S3_URL}";
            s3forcepathstyle = true;
          };
        };
      };
    };
  };

  systemd.services.loki.serviceConfig = {
    EnvironmentFile = config.sops.secrets."loki-env".path;
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/loki"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/loki 0750 loki loki -"
  ];
}
