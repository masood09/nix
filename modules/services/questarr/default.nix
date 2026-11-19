# Questarr — *arr-style video game manager (https://github.com/Doezer/Questarr),
# run as a Podman OCI container because it is in neither nixpkgs nor nixflix.
# It has its own login (no OIDC), so Caddy proxies straight to it with no
# Authentik in front. It stays off the VPN: it only talks to IGDB and to the
# indexers through Prowlarr, the same as the other arrs. Downloads go through
# qBittorrent, which is VPN-confined (modules/services/arr).
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.questarr;
  caddyEnabled = homelabCfg.services.caddy.enable;
  # Not config.users.groups.media.gid: nixflix's slskd module sets
  # `users.groups.media = mkForce {}`, which drops the declared gid (it
  # evaluates to null). The group on disk keeps nixflix's fixed gid, so
  # take the number from nixflix's globals, which is where it comes from.
  mediaGid = config.nixflix.globals.gids.media;

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "questarr";
    inherit (cfg) dataDir;
    user = "questarr";
    # Matches PGID below; the entrypoint chowns /app/data to PUID:PGID.
    group = "media";
    mainServices = ["podman-questarr"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-questarr";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = homelabCfg.services.podman.enable;
        message = "Questarr requires Podman (homelab.services.podman.enable).";
      }
      {
        assertion = config.users.groups ? media;
        message = "Questarr joins the arr stack's media group; enable homelab.services.arr.";
      }
    ];

    homelab = {
      zfs = {
        datasets = {
          questarr = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = cfg.dataDir;
            requiredBy = ["podman-questarr.service"];

            restic = {
              inherit (cfg.zfs.restic) enable;
            };
          };
        };
      };

      services = {
        backup = {
          serviceUnits = ["podman-questarr.service"];
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

    virtualisation = {
      oci-containers = {
        containers = {
          questarr = {
            inherit (cfg) image;
            autoStart = true;

            volumes = [
              "${toString cfg.dataDir}:/app/data"
              "${toString cfg.mediaDir}:${toString cfg.mediaDir}"
            ];

            environment = {
              TZ = config.time.timeZone;

              # The image's entrypoint (LinuxServer convention) starts as root,
              # remaps its questarr user to PUID/PGID, chowns /app/data to
              # match, then drops privileges. Do not set the container `user`:
              # the remap needs root and the container exits otherwise.
              # Primary group media so files Questarr writes into the shared
              # library stay group-accessible to the other media services.
              PUID = toString cfg.userId;
              PGID = toString mediaGid;
              UMASK = "002";

              HOST = "127.0.0.1";
              PORT = toString cfg.listenPort;
              # One proxy hop (Caddy on loopback).
              TRUST_PROXY = "1";
              SQLITE_DB_PATH = "/app/data/sqlite.db";
            };

            environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;

            # Host networking: Questarr reaches Prowlarr on loopback and
            # qBittorrent at the VPN namespace address without Podman NAT,
            # and still binds only to 127.0.0.1 (HOST above).
            extraOptions = [
              "--network=host"
            ];
          };
        };
      };
    };

    systemd = lib.mkMerge [
      permSvc.systemd
      {
        services = {
          podman-questarr = {
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir cfg.mediaDir];
            };
          };
        };

        tmpfiles = {
          settings = {
            "10-questarr" = {
              ${cfg.gamesDir} = {
                d = {
                  user = "questarr";
                  group = "media";
                  mode = "2775";
                };
              };
            };
          };
        };
      }
    ];

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = cfg.zfs.enable;
      directories = [cfg.dataDir];
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.listenPort}
            '';
          };
        };
      };
    };
  };
}
