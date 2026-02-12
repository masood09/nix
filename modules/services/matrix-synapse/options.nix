{
  config,
  lib,
  ...
}: let
  zfsDatasetOpts = lib.types.submodule (_: {
    options = {
      dataset = lib.mkOption {
        type = lib.types.str;
        description = "ZFS dataset name.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "ZFS properties to apply to the dataset.";
      };
    };
  });
in {
  options.homelab.services.matrix = {
    rootDomain = lib.mkOption {
      type = lib.types.str;
      default = "chat.${config.networking.domain}";
    };

    openFirewall = lib.mkEnableOption "Open ports in the firewall";

    synapse = {
      enable = lib.mkEnableOption "Whether to enable Matrix Synapse.";
      enableCaddy = lib.mkEnableOption "Whether to enable local Caddy";

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/matrix-synapse";
      };

      mediaDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/matrix-synapse-media";
      };

      webDomain = lib.mkOption {
        type = lib.types.str;
        default = "chat.${config.homelab.services.matrix.rootDomain}";
      };

      listenAddress = lib.mkOption {
        default = ["127.0.0.1"];
        type = lib.types.listOf lib.types.str;
      };

      listenPort = lib.mkOption {
        default = 8008;
        type = lib.types.port;
      };

      zfs = {
        enable = lib.mkEnableOption "Store Matrix Synapse data on ZFS dataset.";

        dataDir = lib.mkOption {
          type = zfsDatasetOpts;
          default = {
            dataset = "fpool/fast/services/matrix-synapse";
            properties = {
              atime = "off";
              compression = "zstd";
              recordsize = "16K";
              logbias = "latency";
              xattr = "sa";
              acltype = "posixacl";
              redundant_metadata = "most";
            };
          };
        };

        mediaDir = lib.mkOption {
          type = zfsDatasetOpts;
          default = {
            dataset = "dpool/tank/services/matrix-synapse-media";
            properties = {
              atime = "off";
              compression = "zstd";
              recordsize = "1M";
              logbias = "throughput";
              redundant_metadata = "most";
            };
          };
        };
      };

      mas = {
        userId = lib.mkOption {
          default = 3010;
          type = lib.types.ints.u16;
        };

        groupId = lib.mkOption {
          default = 3010;
          type = lib.types.ints.u16;
        };

        http = {
          trusted_proxies = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["127.0.0.1"];
          };

          web = {
            port = lib.mkOption {
              type = lib.types.port;
              default = 8910;
            };

            bindAddresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = ["127.0.0.1"];
            };
          };

          health = {
            port = lib.mkOption {
              type = lib.types.port;
              default = 8911;
            };

            bindAddresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = ["127.0.0.1"];
            };
          };
        };
      };
    };

    rtc = {
      enable = lib.mkEnableOption "Whether to enable RTC services";

      lk-jwt-service = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 8912;
        };
      };

      livekit = {
        bindAddress = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["127.0.0.1"];
        };

        rtcExternalIP = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        ports = {
          port = lib.mkOption {
            type = lib.types.port;
            default = 7880;
          };

          tcpPort = lib.mkOption {
            type = lib.types.port;
            default = 7881;
          };

          rtcPortRangeStart = lib.mkOption {
            type = lib.types.port;
            default = 50100;
          };

          rtcPortRangeEnd = lib.mkOption {
            type = lib.types.port;
            default = 50200;
          };
        };
      };
    };
  };
}
