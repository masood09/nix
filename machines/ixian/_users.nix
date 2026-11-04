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
          # Human UIDs are unique fleet-wide, like service UIDs: 1001 belongs to
          # zainahmed on sonic, so this console account takes the next free one
          # (see docs/service-registry.org). NixOS rewrites /etc/passwd but never
          # re-owns the already-persisted home directory, so a change here needs
          # the chown runbook in machines/ixian/install.org.
          uid = 1002;
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
