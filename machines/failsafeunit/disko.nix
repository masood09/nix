let
  bdisk1 = "ata-Patriot_P220_128GB_P220HHBB241107006885";

  ddisk1 = "wwn-0x5000cca23b3f1010";
  ddisk2 = "wwn-0x5000cca23b43d33c";
  ddisk3 = "wwn-0x5000cca23b43d178";
  ddisk4 = "wwn-0x5000cca23b27fb10";
  ddisk5 = "wwn-0x5000cca23b43bbcc";
  ddisk6 = "wwn-0x5000cca23b364e38";
  ddisk7 = "wwn-0x5000cca23b45602c";
  ddisk8 = "wwn-0x5000cca23b294294";
  ddisk9 = "wwn-0x5000cca23b3ffc78";
  ddisk10 = "wwn-0x5000cca23b43f5c0";
  ddisk11 = "wwn-0x5000cca23b3f1f04";
  ddisk12 = "wwn-0x5000cca23b43b7a8";
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

      data1 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk1}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk2}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data3 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk3}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data4 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk4}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data5 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk5}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data6 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk6}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data7 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk7}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data8 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk8}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data9 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk9}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data10 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk10}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data11 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk11}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };

      data12 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk12}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "DataStore";
              };
            };
          };
        };
      };
    };

    zpool = {
      dpool = {
        type = "zpool";

        mode = {
          topology = {
            type = "topology";

            vdev = [
              {
                mode = "mirror";

                members = [
                  "data1"
                  "data2"
                ];
              }
              {
                mode = "mirror";

                members = [
                  "data3"
                  "data4"
                ];
              }
              {
                mode = "mirror";

                members = [
                  "data5"
                  "data6"
                ];
              }
              {
                mode = "mirror";

                members = [
                  "data7"
                  "data8"
                ];
              }
              {
                mode = "mirror";

                members = [
                  "data9"
                  "data10"
                ];
              }
              {
                mode = "mirror";

                members = [
                  "data11"
                  "data12"
                ];
              }
            ];
          };
        };

        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "zstd";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };

        datasets = {
          DataStore = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore";
            options."com.sun:auto-snapshot" = "false";
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
