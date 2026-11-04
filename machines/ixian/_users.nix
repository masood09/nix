# Console gaming account, plus the homelab.desktop.gaming.user binding that names it.
{config, ...}: let
  gamingUser = config.homelab.desktop.gaming.user;
in {
  config = {
    # Deliberately not homelab.primaryUser: on ixian the primary user is the
    # admin (masoodahmed), who keeps wheel and SSH access, while this account
    # is the unprivileged one that autologins into Steam Gaming Mode.
    homelab = {
      desktop = {
        gaming = {
          user = "voyageonwheels";
        };
      };
    };

    users = {
      users = {
        ${gamingUser} = {
          isNormalUser = true;
          uid = 1001;
          description = gamingUser;

          extraGroups = [
            "audio"
            "input"
            "video"
          ];
        };
      };
    };
  };
}
