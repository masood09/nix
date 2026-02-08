{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.matrix-synapse;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    services = {
      matrix-synapse = {
        enable = true;
      };
    };
  };
}
