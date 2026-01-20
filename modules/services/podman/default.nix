{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  podmanCfg = homelabCfg.services.podman;
in {
  options.homelab.services = {
    podman = {
      enable = lib.mkEnableOption "Whether to enable Podman.";

      zfs = {
        enable = lib.mkEnableOption "Store Podman dataDir on a ZFS dataset.";

        dataset = lib.mkOption {
          type = lib.types.str;
          default = "dpool/tank/services/podman";
          description = "ZFS dataset to create and mount at dataDir.";
        };

        properties = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {};
          description = "ZFS properties for the dataset.";
        };
      };
    };
  };

  config = lib.mkIf podmanCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.podman = lib.mkIf podmanCfg.zfs.enable {
      inherit (podmanCfg.zfs) dataset properties;

      enable = true;
      mountpoint = "/var/lib/containers";

      requiredBy = [
        "podman.service"
      ];

      restic = {
        enable = false;
      };
    };

    virtualisation.podman = {
      enable = true;
    };

    # Service hardening + mount ordering
    systemd = {
      services.podman = lib.mkMerge [
        {
          # Unit-level ordering / mount requirements
          unitConfig = {
            RequiresMountsFor = ["/var/lib/containers"];
          };
        }

        (lib.mkIf podmanCfg.zfs.enable {
          requires = ["zfs-dataset-podman.service"];
          after = ["zfs-dataset-podman.service"];
        })
      ];

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d /var/lib/containers 0700 root root -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !podmanCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          "/var/lib/containers"
        ];
      };
  };
}
