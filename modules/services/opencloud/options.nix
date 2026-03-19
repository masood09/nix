# Options — OpenCloud file sync (domain, port, ZFS, OAuth).
{
  config,
  lib,
  ...
}: {
  options = {
    homelab = {
      services = {
        opencloud = {
          enable = lib.mkEnableOption "Whether to enable Open Cloud.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "cloud.${config.networking.domain}";
            description = "Domain name for the OpenCloud web interface.";
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/opencloud";
            description = "Directory for OpenCloud data storage.";
          };

          logLevel = lib.mkOption {
            type = lib.types.enum [
              "debug"
              "info"
              "warning"
              "error"
            ];

            default = "info";
            description = "Log verbosity level for OpenCloud.";
          };

          userId = lib.mkOption {
            default = 3008;
            type = lib.types.ints.u16;
            description = "UID for the OpenCloud service user.";
          };

          groupId = lib.mkOption {
            default = 3008;
            type = lib.types.ints.u16;
            description = "GID for the OpenCloud service group.";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 8905;
            description = "Port for the OpenCloud HTTP server.";
          };

          oidc = {
            clientId = lib.mkOption {
              type = lib.types.str;
              default = "OpenCloud";
              description = "OIDC client ID for OpenCloud authentication.";
            };

            idpDomain = lib.mkOption {
              type = lib.types.str;
              default = "auth.${config.networking.domain}";
              description = "Domain of the OIDC identity provider.";
            };
          };

          collabora = {
            port = lib.mkOption {
              type = lib.types.port;
              default = 8906;
              description = "Port for the Collabora Online document editor.";
            };
          };

          wopi = {
            port = lib.mkOption {
              type = lib.types.port;
              default = 8907;
              description = "Port for the WOPI (Web Application Open Platform Interface) server.";
            };
          };

          metrics = {
            port = lib.mkOption {
              type = lib.types.port;
              default = 8908;
              description = "Port for the OpenCloud metrics endpoint.";
            };
          };

          zfs = {
            enable = lib.mkEnableOption "Whether to create ZFS datasets for OpenCloud data/meta.";

            rootDataset = lib.mkOption {
              type = lib.types.str;
              default = "fpool/fast/services/opencloud";
              description = "ZFS dataset for the OpenCloud root data directory.";
            };

            etcDataset = lib.mkOption {
              type = lib.types.str;
              default = "fpool/fast/services/opencloud-etc";
              description = "ZFS dataset for OpenCloud configuration data.";
            };

            idmDataset = lib.mkOption {
              type = lib.types.str;
              default = "fpool/fast/services/opencloud-idm";
              description = "ZFS dataset for OpenCloud identity management data.";
            };

            natsDataset = lib.mkOption {
              type = lib.types.str;
              default = "fpool/fast/services/opencloud-nats";
              description = "ZFS dataset for OpenCloud NATS message queue data.";
            };

            searchDataset = lib.mkOption {
              type = lib.types.str;
              default = "fpool/fast/services/opencloud-search";
              description = "ZFS dataset for OpenCloud search index data.";
            };

            storageMetaDataset = lib.mkOption {
              type = lib.types.str;
              default = "fpool/fast/services/opencloud-storage-meta";
              description = "ZFS dataset for OpenCloud storage metadata.";
            };

            storageOCMDataset = lib.mkOption {
              type = lib.types.str;
              default = "fpool/fast/services/opencloud-storage-ocm";
              description = "ZFS dataset for OpenCloud OCM (Open Cloud Mesh) federation storage.";
            };

            storageUserDataset = lib.mkOption {
              type = lib.types.str;
              default = "dpool/tank/services/opencloud-storage-user";
              description = "ZFS dataset for OpenCloud user file storage.";
            };

            etcProperties = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "ZFS properties for the etc dataset.";

              default = {
                recordsize = "16K";
                logbias = "latency";
              };
            };

            idmProperties = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "ZFS properties for the IDM dataset.";

              default = {
                recordsize = "16K";
                logbias = "latency";
              };
            };

            natsProperties = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "ZFS properties for the NATS dataset.";

              default = {
                recordsize = "16K";
                logbias = "latency";
                primarycache = "all";
              };
            };

            searchProperties = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "ZFS properties for the search dataset.";

              default = {
                recordsize = "32K";
                primarycache = "all";
              };
            };

            storageMetaProperties = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "ZFS properties for the storage metadata dataset.";

              default = {
                recordsize = "16K";
                logbias = "latency";
              };
            };

            storageOCMProperties = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "ZFS properties for the OCM storage dataset.";

              default = {
                recordsize = "16K";
                logbias = "latency";
              };
            };

            storageUserProperties = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "ZFS properties for the user file storage dataset.";

              default = {
                recordsize = "1M";
                primarycache = "all";
              };
            };
          };
        };
      };
    };
  };
}
