{config, ...}: let
  sshCfg = config.homelab.services.ssh;
in {
  imports = [
    ./options.nix
  ];

  config = {
    services.openssh = {
      enable = true;
      ports = [sshCfg.listenPort];

      settings = {
        # Block root completely
        PermitRootLogin = "no";

        # Key-only auth: stop PAM/password/interactive attempts
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;

        PubkeyAuthentication = "yes";
        AuthenticationMethods = "publickey";

        # Reduce brute-force effectiveness/noise
        MaxAuthTries = 3;
        LoginGraceTime = 20;

        AllowUsers = sshCfg.allowUsers;
      };

      openFirewall = true;
    };
  };
}
