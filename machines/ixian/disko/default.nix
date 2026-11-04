# Disko layout — encrypted LUKS+LVM system disk plus independent encrypted model disk.
{config, ...}: let
  byId = id: "/dev/disk/by-id/${id}";

  # The model disk is the machine's only data disk; its by-id name lives in
  # homelab.disks.data (machines/ixian/default.nix).
  dataIds = config.homelab.disks.data;
in {
  imports = [
    ../../../modules/nixos/disko/_root-disk-single-ext4.nix
  ];

  config = {
    # This module declares an explicit `config` attribute, so assertions must
    # live inside it (heartbeat's dataDisks.nix keeps them top-level because it
    # writes `disko.devices` directly).
    assertions = [
      {
        assertion = builtins.length dataIds == 1;
        message = "ixian's /srv/models disk needs exactly 1 entry in homelab.disks.data (you have ${toString (builtins.length dataIds)}).";
      }
    ];

    disko = {
      devices = {
        disk = {
          models = {
            type = "disk";
            device = byId (builtins.elemAt dataIds 0);
            content = {
              type = "gpt";
              partitions = {
                models = {
                  size = "100%";
                  content = {
                    type = "luks";
                    name = "cryptmodels";
                    settings = {
                      allowDiscards = true;
                    };
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/srv/models";
                      mountOptions = [
                        "noatime"
                        "nofail"
                        "x-systemd.device-timeout=10s"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
