{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  acmeCfg = homelabCfg.services.acme;
in {
  security.acme = lib.mkIf acmeCfg.enable {
    acceptTerms = true;

    defaults = {
      inherit (acmeCfg) email;
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      credentialFiles = {
        "CLOUDFLARE_DNS_API_TOKEN_FILE" = acmeCfg.cloudflareAPIKeyPath;
      };
    };
  };

  environment.persistence."/nix/persist" =
    lib.mkIf (acmeCfg.enable && homelabCfg.impermanence && !homelabCfg.isRootZFS) {
      directories = [
        "/var/lib/acme"
      ];
    };
}
