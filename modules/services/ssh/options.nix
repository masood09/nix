{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options.homelab.services.ssh = {
    listenPort = lib.mkOption {
      default = 22222;
      type = lib.types.port;
      description = "The port of the SSH server.";
    };

    # Optional: restrict who can even attempt login
    allowUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [homelabCfg.primaryUser.userName];
      description = "If non-empty, only these users may SSH in (AllowUsers).";
    };
  };
}
