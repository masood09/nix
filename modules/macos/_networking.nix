# macOS networking — sets hostname/computerName/localHostName.
# Also defines the homelab options needed on Darwin (primaryUser, role, networking).
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.networking;
in {
  options = {
    homelab = {
      networking = {
        hostName = lib.mkOption {
          type = lib.types.str;
          description = "The hostname of the machine.";
        };
      };

      primaryUser = {
        userName = lib.mkOption {
          default = "masoodahmed";
          type = lib.types.str;
          description = "Primary User of the system";
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

      role = lib.mkOption {
        default = "server";
        type = lib.types.enum ["desktop" "server"];
        description = ''
          The role of this machine. Could be server or desktop.
        '';
      };
    };
  };

  config = {
    networking = {
      inherit (cfg) hostName;
      computerName = cfg.hostName;
      localHostName = cfg.hostName;
    };
  };
}
