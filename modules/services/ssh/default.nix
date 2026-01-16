{
  config,
  lib,
  ...
}: let
  sshCfg = config.homelab.services.ssh;
in {
  services = lib.mkIf sshCfg.enable {
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
