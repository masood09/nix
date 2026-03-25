# User management — immutable users with sops-managed passwords.
# Defines the primary user account and their SSH authorized keys.
# Password is read from sops at activation time (mutableUsers = false).
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options = {
    homelab = {
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

  config = {
    users = {
      defaultUserShell =
        if homelabCfg.programs.zsh.enable or false
        then pkgs.zsh
        else pkgs.bash;

      # All user accounts are declarative; no passwd/useradd changes persist
      mutableUsers = false;

      users = {
        ${homelabCfg.primaryUser.userName} = {
          isNormalUser = true;
          uid = homelabCfg.primaryUser.userId;
          description = homelabCfg.primaryUser.userName;

          extraGroups =
            [
              "networkmanager"
              "wheel"
            ]
            # Desktop users need direct access to audio/input/video devices
            ++ lib.optionals (homelabCfg.role == "desktop") [
              "audio"
              "input"
              "video"
            ];

          openssh = {
            authorizedKeys = {
              keys = homelabCfg.primaryUser.sshPublicKeys;
            };
          };

          hashedPasswordFile = config.sops.secrets."user/password".path;
        };
      };
    };
  };
}
