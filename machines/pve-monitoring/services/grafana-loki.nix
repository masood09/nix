{
  services = {
    loki = {
      enable = true;

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
          path_prefix = "/tmp/loki";
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
          filesystem = {
            directory = "/tmp/loki/chunks";
          };
        };
      };
    };
  };
}
