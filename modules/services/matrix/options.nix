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
      description = "Root domain for the Matrix deployment.";
    };

    openFirewall = lib.mkEnableOption "Whether to open ports in the firewall.";

    synapse = {
      enable = lib.mkEnableOption "Whether to enable Matrix Synapse.";
      enableCaddy = lib.mkEnableOption "Whether to enable local Caddy.";

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/matrix-synapse";
        description = "Directory for Matrix Synapse persistent data.";
      };

      mediaDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/matrix-synapse-media";
        description = "Directory for Matrix Synapse media storage.";
      };

      webDomain = lib.mkOption {
        type = lib.types.str;
        default = "chat.${config.homelab.services.matrix.rootDomain}";
        description = "Domain name for the Synapse web client.";
      };

      listenAddress = lib.mkOption {
        default = ["127.0.0.1"];
        type = lib.types.listOf lib.types.str;
        description = "Addresses for Synapse to bind to.";
      };

      listenPort = lib.mkOption {
        default = 8008;
        type = lib.types.port;
        description = "Port for the Synapse HTTP listener.";
      };

      zfs = {
        enable = lib.mkEnableOption "Whether to store Matrix Synapse data on a ZFS dataset.";

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
          description = "ZFS dataset configuration for Synapse data directory.";
        };

        mediaDir = lib.mkOption {
          type = zfsDatasetOpts;
          default = {
            dataset = "dpool/tank/services/matrix-synapse-media";
            properties = {
              compression = "lz4";
              recordsize = "1M";
              logbias = "throughput";
              redundant_metadata = "most";
            };
          };
          description = "ZFS dataset configuration for Synapse media directory.";
        };
      };

      mas = {
        userId = lib.mkOption {
          default = 3010;
          type = lib.types.ints.u16;
          description = "UID for the Matrix Authentication Service user.";
        };

        groupId = lib.mkOption {
          default = 3010;
          type = lib.types.ints.u16;
          description = "GID for the Matrix Authentication Service group.";
        };

        http = {
          trusted_proxies = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["127.0.0.1"];
            description = "Trusted proxy addresses for MAS.";
          };

          web = {
            port = lib.mkOption {
              type = lib.types.port;
              default = 8910;
              description = "Port for the MAS web interface.";
            };

            bindAddresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = ["127.0.0.1"];
              description = "Addresses for the MAS web interface to bind to.";
            };
          };

          health = {
            port = lib.mkOption {
              type = lib.types.port;
              default = 8911;
              description = "Port for the MAS health check endpoint.";
            };

            bindAddresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = ["127.0.0.1"];
              description = "Addresses for the MAS health endpoint to bind to.";
            };
          };
        };
      };
    };

    rtc = {
      enable = lib.mkEnableOption "Whether to enable RTC services.";

      lk-jwt-service = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 8912;
          description = "Port for the LiveKit JWT service.";
        };
      };

      livekit = {
        bindAddress = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["127.0.0.1"];
          description = "Addresses for LiveKit to bind to.";
        };

        rtcExternalIP = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to use an external IP for RTC traffic.";
        };

        ports = {
          port = lib.mkOption {
            type = lib.types.port;
            default = 7880;
            description = "Main LiveKit server port.";
          };

          tcpPort = lib.mkOption {
            type = lib.types.port;
            default = 7881;
            description = "LiveKit TCP port for RTC traffic.";
          };

          rtcPortRangeStart = lib.mkOption {
            type = lib.types.port;
            default = 50100;
            description = "Start of the UDP port range for RTC traffic.";
          };

          rtcPortRangeEnd = lib.mkOption {
            type = lib.types.port;
            default = 50200;
            description = "End of the UDP port range for RTC traffic.";
          };
        };
      };
    };
  };
}
