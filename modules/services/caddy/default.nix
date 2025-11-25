{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  caddyEnabled = homelabCfg.services.caddy.enable;
in {
  services = lib.mkIf caddyEnabled {
    caddy = {
      enable = caddyEnabled;
    };
  };

  security = lib.mkIf caddyEnabled {
    acme = {
      acceptTerms = true;

      defaults = {
        email = "letsencrypt@mantannest.com";
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        credentialFiles = {
          "CLOUDFLARE_DNS_API_TOKEN_FILE" = homelabCfg.services.acme.cloudflareAPIKeyPath;
        };
      };
    };
  };

  environment.persistence."/nix/persist" =
    lib.mkIf (caddyEnabled && homelabCfg.impermanence && !homelabCfg.isRootZFS) {
      directories = [
        "/var/lib/acme"
      ];
    };

  networking.firewall.allowedTCPPorts = lib.mkIf caddyEnabled [
    80
    443
  ];
}
