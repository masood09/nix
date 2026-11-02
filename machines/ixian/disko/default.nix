# Disko layout — encrypted LUKS+LVM system disk plus independent encrypted model disk.
{
  imports = [
    ../../../modules/nixos/disko/_root-disk-single-ext4.nix
  ];

  config = {
    disko = {
      devices = {
        disk = {
          models = {
            type = "disk";
            device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_24504CBE7C73";
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
