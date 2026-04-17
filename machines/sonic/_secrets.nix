# Sops secret declarations — paths, owners, and restart triggers for this machine.
{
  config = {
    sops = {
      secrets = {
        "alloy/.env" = {
          restartUnits = ["alloy.service"];
        };

        # Primary desktop user (zainahmed) — also the LUKS passphrase for
        # pam_fde_boot_pw keyring auto-unlock. Must match the LUKS passphrase.
        "user/password" = {
          sopsFile = ./secrets.sops.yaml;
          neededForUsers = true;
        };

        # Admin user (masoodahmed) — SSH-only, passwordless sudo via wheel.
        "user/masoodahmed-password" = {
          sopsFile = ./secrets.sops.yaml;
          neededForUsers = true;
        };

        "zed/discord-zfs-webhook" = {};
      };
    };
  };
}
