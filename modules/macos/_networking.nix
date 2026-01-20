{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.networking;
in {
  options.homelab = {
    networking = {
      hostName = lib.mkOption {
        type = lib.types.str;
        description = "The hostname of the machine.";
      };
    };

    primaryUser = {
      userName = lib.mkOption {
        default = "masoodahmed";
        type = lib.types.str;
        description = "Primary User of the system";
      };

      sshPublicKey = lib.mkOption {
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfTOXZ6W+DhUQcytGQ1ob+eFPQwbyiTB8wXnRSiYqpK";
        type = lib.types.str;
        description = ''
          Public SSH key to be added to authrorized keys
        '';
      };
    };

    role = lib.mkOption {
      default = "server";
      type = lib.types.enum ["desktop" "server"];
      description = ''
        The role of this machine. Could be server or desktop.
      '';
    };
  };
  
  config = {
    networking = {
      inherit (cfg) hostName;
      computerName = cfg.hostName;
      localHostName = cfg.hostName;
    };
  };
}
