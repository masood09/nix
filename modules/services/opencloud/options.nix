{
  config,
  lib,
  ...
}: {
  options.homelab.services.opencloud = {
    enable = lib.mkEnableOption "Whether to enable Open Cloud.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "cloud.${config.networking.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/opencloud";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [
        "debug"
        "info"
        "warning"
        "error"
      ];

      default = "info";
    };

    userId = lib.mkOption {
      default = 3008;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3008;
      type = lib.types.ints.u16;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8905;
    };

    oidc = {
      clientId = lib.mkOption {
        type = lib.types.str;
        default = "OpenCloud";
      };

      idpDomain = lib.mkOption {
        type = lib.types.str;
        default = "auth.${config.networking.domain}";
      };
    };

    collabora = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 8906;
      };
    };

    wopi = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 8907;
      };
    };

    metrics = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 8908;
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Create ZFS datasets for OpenCloud data/meta.";

      rootDataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/opencloud";
      };

      etcDataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/opencloud-etc";
      };

      idmDataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/opencloud-idm";
      };

      natsDataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/opencloud-nats";
      };

      searchDataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/opencloud-search";
      };

      storageMetaDataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/opencloud-storage-meta";
      };

      storageOCMDataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/opencloud-storage-ocm";
      };

      storageUserDataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/opencloud-storage-user";
      };

      etcProperties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;

        default = {
          recordsize = "16K";
          logbias = "latency";
        };
      };

      idmProperties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;

        default = {
          recordsize = "16K";
          logbias = "latency";
        };
      };

      natsProperties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;

        default = {
          recordsize = "16K";
          logbias = "latency";
          primarycache = "all";
        };
      };

      searchProperties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;

        default = {
          recordsize = "32K";
          primarycache = "all";
        };
      };

      storageMetaProperties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;

        default = {
          recordsize = "16K";
          logbias = "latency";
        };
      };

      storageOCMProperties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;

        default = {
          recordsize = "16K";
          logbias = "latency";
        };
      };

      storageUserProperties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;

        default = {
          recordsize = "1M";
          primarycache = "all";
        };
      };
    };
  };
}
