# Questarr — game library manager running as a Podman container.
# The service is fronted by Authentik's embedded Proxy Provider outpost.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.questarr;
  podmanEnabled = homelabCfg.services.podman.enable;
  caddyEnabled = config.services.caddy.enable;
  mediaGroupId = config.nixflix.globals.gids.media;
  podmanFirewallInterface =
    if !config.networking.nftables.enable
    then "podman+"
    else "podman*";
  prowlarrPort = config.nixflix.prowlarr.config.hostConfig.port;
  sabnzbdPort = config.nixflix.usenetClients.sabnzbd.settings.misc.port;
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "questarr";
    inherit (cfg) dataDir;
    user = "questarr";
    group = "questarr";
    mainServices = ["podman-questarr"];
    mode = "0750";
    zfs = {
      enable = true;
      datasetServiceName = "zfs-dataset-arr";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf (cfg.enable && podmanEnabled) {
    assertions = [
      {
        assertion = homelabCfg.services.arr.enable;
        message = "Questarr requires homelab.services.arr.enable so its state directory is backed by the existing Arr ZFS dataset.";
      }
    ];

    sops = {
      templates = {
        "questarr.env" = {
          content = ''
            JWT_SECRET=${config.sops.placeholder."questarr/jwt-secret"}
            CREDENTIALS_ENCRYPTION_KEY=${config.sops.placeholder."questarr/credentials-encryption-key"}
          '';
          mode = "0400";
          restartUnits = ["podman-questarr.service"];
        };
      };
    };

    # Add Questarr to the existing Arr dataset's mount ordering. The Arr module
    # owns the dataset and its backup configuration.
    homelab = {
      zfs = {
        datasets = {
          arr = {
            requiredBy = ["podman-questarr.service"];
          };
        };
      };
    };

    virtualisation = {
      oci-containers = {
        containers = {
          questarr = {
            # renovate: datasource=docker depName=ghcr.io/doezer/questarr
            image = "ghcr.io/doezer/questarr:v1.4.2";
            autoStart = true;

            environment = {
              HOST = "0.0.0.0";
              PORT = "5000";
              PUID = toString cfg.userId;
              PGID = toString cfg.groupId;
              TRUST_PROXY = "1";
              DISABLE_HSTS = "true";
            };

            environmentFiles = [
              config.sops.templates."questarr.env".path
            ];

            volumes = [
              "${cfg.dataDir}:/app/data"
              "${cfg.mediaDir}:/data/library"
              "${cfg.downloadsDir}:/data/downloads"
            ];

            ports = [
              "${cfg.listenAddress}:${toString cfg.listenPort}:5000"
            ];

            extraOptions = [
              "--group-add=${toString mediaGroupId}"
            ];
          };
        };
      };
    };

    users = {
      users = {
        questarr = {
          isSystemUser = true;
          group = "questarr";
          extraGroups = ["media"];
          uid = cfg.userId;
        };
      };

      groups = {
        questarr = {
          gid = cfg.groupId;
        };
      };
    };

    inherit (permSvc) systemd;

    networking = {
      firewall = {
        interfaces = {
          tailscale0 = {
            allowedTCPPorts = [cfg.listenPort];
          };

          "${podmanFirewallInterface}" = {
            allowedTCPPorts = lib.unique (
              (lib.optional homelabCfg.services.arr.prowlarr.enable prowlarrPort)
              ++ lib.optional homelabCfg.services.arr.sabnzbd.enable sabnzbdPort
            );
          };
        };
      };
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            # Full Proxy Provider mode: the embedded outpost performs SSO and
            # then forwards to its manually configured internal host.
            extraConfig = ''
              reverse_proxy https://auth.${config.networking.domain} {
                header_up Host {http.request.host}
              }
            '';
          };
        };
      };
    };
  };
}
