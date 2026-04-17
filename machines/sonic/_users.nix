# Admin user for remote management — sudo (wheel) + SSH access, no desktop.
# masoodahmed's home is not persisted (tmpfs root wipes it on reboot);
# this account exists solely for SSH-in administration.
{config, ...}: {
  config = {
    users = {
      users = {
        masoodahmed = {
          isNormalUser = true;
          uid = 1000;
          description = "masoodahmed";

          extraGroups = [
            "wheel"
          ];

          openssh = {
            authorizedKeys = {
              keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfTOXZ6W+DhUQcytGQ1ob+eFPQwbyiTB8wXnRSiYqpK"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBv3kEMJd555u7Rb8ofRfC3K2k5v9qjnz9tsbxli9tp8 me@ahmedmasood.com"
              ];
            };
          };

          hashedPasswordFile = config.sops.secrets."user/masoodahmed-password".path;
        };
      };
    };
  };
}
