let
  bdisk1 = "ata-Patriot_P220_128GB_P220HHBB241107006885";
in {
  disko.devices = {
    disk = {
      boot = {
        device = "/dev/disk/by-id/${bdisk1}";
        type = "disk";

        content = {
          type = "gpt";

          partitions = {
            ESP = {
              type = "EF00";
              size = "512M";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            nix = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";

                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/nix";
                };
              };
            };
          };
        };
      };
    };

    nodev."/" = {
      fsType = "tmpfs";

      mountOptions = [
        "size=4G"
        "defaults"
        "mode=755"
      ];
    };
  };
}
