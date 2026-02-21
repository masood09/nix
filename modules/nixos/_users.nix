{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options.homelab = {
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
    };
  };

  config = {
    users = {
      defaultUserShell =
        if homelabCfg.programs.zsh.enable or false
        then pkgs.zsh
        else pkgs.bash;

      mutableUsers = false;

      users = {
        ${homelabCfg.primaryUser.userName} = {
          isNormalUser = true;
          description = homelabCfg.primaryUser.userName;

          extraGroups = [
            "networkmanager"
            "wheel"
          ];

          openssh.authorizedKeys.keys = [
            homelabCfg.primaryUser.sshPublicKey
          ];

          hashedPasswordFile = config.sops.secrets."user/password".path;
        };
      };
    };
  };
}
