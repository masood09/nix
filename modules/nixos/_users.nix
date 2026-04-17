# User management — immutable users with sops-managed passwords.
# Defines the primary user account and their SSH authorized keys.
# Password is read from sops at activation time (mutableUsers = false).
# Wheel (sudo) membership is gated on homelab.primaryUser.wheel (default: true)
# so machines can run a non-admin primary user (e.g. sonic's kid account).
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
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
            ]
            ++ lib.optionals homelabCfg.primaryUser.wheel [
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
