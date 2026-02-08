{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.matrix-synapse;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    homelab.zfs.datasets = lib.mkIf cfg.zfs.enable {
      matrix-synapse = {
        enable = true;

        inherit (cfg.zfs.dataDir) dataset properties;

        mountpoint = cfg.dataDir;
        requiredBy = ["matrix-synapse.service"];

        restic = {
          enable = true;
        };
      };

      matrix-synapse-media = {
        enable = true;

        inherit (cfg.zfs.mediaDir) dataset properties;

        mountpoint = cfg.mediaDir;
        requiredBy = ["matrix-synapse.service"];

        restic = {
          enable = true;
        };
      };
    };

    services = {
      matrix-synapse = {
        enable = true;

        inherit (cfg) dataDir;

        settings = {
          media_store_path = cfg.mediaDir;
          server_name = cfg.serverName;
          public_baseurl = cfg.webDomain;

          listeners = [
            {
              port = cfg.listenPort;
              bind_addresses = cfg.listenAddress;
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [
                {
                  names = [
                    "client"
                    "federation"
                  ];
                  compress = true;
                }
              ];
            }
          ];
        };
      };
    };
  };
}
