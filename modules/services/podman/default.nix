{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  podmanCfg = homelabCfg.services.podman;
in {
  imports = [
    ./options.nix
  ];

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
      autoPrune.enable = true;
    };

    networking.firewall.interfaces = let
      matchAll =
        if !config.networking.nftables.enable
        then "podman+"
        else "podman*";
    in {
      "${matchAll}".allowedUDPPorts = [53];
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        podman = lib.mkMerge [
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

        podman-permissions = {
          description = "Fix Babybuddy dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = ["podman.service"];
          after =
            ["local-fs.target"]
            ++ lib.optionals podmanCfg.zfs.enable [
              "zfs-dataset-podman.service"
            ];
          requires = lib.optionals podmanCfg.zfs.enable [
            "zfs-dataset-podman.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown -R root:root /var/lib/containers
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d /var/lib/containers 0700 root root -"
        "z /var/lib/containers 0700 root root -"
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
