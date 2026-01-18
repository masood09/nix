{
  config,
  lib,
  ...
}: let
  sshCfg = config.homelab.services.ssh;
in {
  options.homelab.services.ssh = {
    listenPort = lib.mkOption {
      default = 22222;
      type = lib.types.port;
      description = "The port of the SSH server.";
    };
  };

  config = {
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
  };
}
