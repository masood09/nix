# Podman — rootless container runtime with auto-pruning.
# Used by services that run OCI containers (BabyBuddy, IT-Tools, etc.).
# Opens DNS port on podman bridge interfaces for container name resolution.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  podmanCfg = homelabCfg.services.podman;

  dataDir = "/var/lib/containers";

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "podman";
    inherit dataDir;
    user = "root";
    group = "root";
    mainServices = ["podman"];
    zfs = {
      inherit (podmanCfg.zfs) enable;
      datasetServiceName = "zfs-dataset-podman";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf podmanCfg.enable {
    # ZFS dataset for dataDir
    homelab = {
      zfs = {
        datasets = {
          podman = lib.mkIf podmanCfg.zfs.enable {
            inherit (podmanCfg.zfs) dataset properties;

            enable = true;
            mountpoint = dataDir;

            requiredBy = [
              "podman.service"
            ];

            restic = {
              enable = false;
            };
          };
        };
      };
    };

    virtualisation = {
      podman = {
        enable = true;
        autoPrune = {
          enable = true;
        };
      };
    };

    networking = {
      firewall = {
        interfaces = let
          matchAll =
            if !config.networking.nftables.enable
            then "podman+"
            else "podman*";
        in {
          "${matchAll}" = {
            allowedUDPPorts = [53];
          };
        };
      };
    };

    inherit (permSvc) systemd;

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !podmanCfg.zfs.enable
      ) {
        persistence = {
          "/nix/persist" = {
            directories = [
              dataDir
            ];
          };
        };
      };
  };
}
