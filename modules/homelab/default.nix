{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./networking
  ];

  options.homelab = {
    impermanence = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Whether impermanence should be enabled.
      '';
    };

    programs = {
      git = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable git.
          '';
        };

        userName = lib.mkOption {
          default = "Masood Ahmed";
          type = lib.types.str;
          description = ''
            The userName option for git.
          '';
        };

        userEmail = lib.mkOption {
          default = "me@ahmedmasood.com";
          type = lib.types.str;
          description = ''
            The userEmail option for git.
          '';
        };
      };
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
