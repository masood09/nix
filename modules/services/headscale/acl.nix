{
  config,
  lib,
  ...
}: let
  headscaleCfg = config.homelab.services.headscale;
in {
  config = lib.mkIf headscaleCfg.enable {
    services = {
      headscale = {
        settings = {
          policy.path = config.sops.secrets."headscale-acl.hujson".path;
        };
      };
    };
  };
}
