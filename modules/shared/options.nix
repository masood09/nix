# Cross-platform homelab options shared by NixOS and nix-darwin.
# Keep only schema here; platform-specific implementation stays in the
# NixOS and macOS module trees.
{lib, ...}: {
  options = {
    homelab = {
      role = lib.mkOption {
        default = "server";
        type = lib.types.enum ["desktop" "server"];
        description = ''
          The role of this machine. Could be server or desktop.
        '';
      };

      purpose = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Free-form description of the machine's purpose.";
      };

      networking = {
        hostName = lib.mkOption {
          type = lib.types.str;
          description = "The hostname of the machine.";
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

        sshPublicKeys = lib.mkOption {
          default = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfTOXZ6W+DhUQcytGQ1ob+eFPQwbyiTB8wXnRSiYqpK"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBv3kEMJd555u7Rb8ofRfC3K2k5v9qjnz9tsbxli9tp8 me@ahmedmasood.com"
          ];
          type = lib.types.listOf lib.types.str;
          description = ''
            Public SSH keys to be added to authorized keys and git allowed signers
          '';
        };
      };
    };
  };
}
