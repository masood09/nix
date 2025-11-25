{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  sops.secrets = {
    "headscale-preauth-key" = {};
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."headscale-preauth-key".path;

    extraUpFlags = [
      "--login-server=https://headscale.mantannest.com"
    ];
  };

  environment.persistence."/nix/persist" = lib.mkIf (!homelabCfg.isRootZFS) {
    directories = [
      "/var/lib/tailscale"
    ];
  };
}
