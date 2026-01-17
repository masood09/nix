{config, ...}: let
  sshCfg = config.homelab.services.ssh;
in {
  services = {
    openssh = {
      enable = true;

      ports = [
        sshCfg.listenPort
      ];

      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };

      openFirewall = true;
    };
  };
}
