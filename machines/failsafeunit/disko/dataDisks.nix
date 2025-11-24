let
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
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
                pool = "dpool";
              };
            };
          };
        };
      };
    };
  };
}
