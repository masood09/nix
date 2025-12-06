{
  config,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
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

        hashedPasswordFile = config.sops.secrets."user-password".path;
      };
    };
  };
}
