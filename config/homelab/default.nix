{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./networking
    ./programs
  ];

  options.homelab = {
    impermanence = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Whether impermanence should be enabled.
      '';
    };

    role = lib.mkOption {
      default = "server";
      type = lib.types.enum ["desktop" "server"];
      description = ''
        The role of this machine. Could be server or desktop.
      '';
    };

    primaryUser = {
      userId = lib.mkOption {
        default = 1000;
        type = lib.types.int;
        description = ''
          User ID of the user
        '';
      };

      userName = lib.mkOption {
        default = "masoodahmed";
        type = lib.types.str;
        description = ''
          Primary User of the system
        '';
      };

      sshPublicKey = lib.mkOption {
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfTOXZ6W+DhUQcytGQ1ob+eFPQwbyiTB8wXnRSiYqpK";
        type = lib.types.str;
        description = ''
          Public SSH key to be added to authrorized keys
        '';
      };

      shell = lib.mkPackageOption pkgs "bash" {};
    };
  };
}
