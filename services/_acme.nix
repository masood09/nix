{config, ...}: {
  sops.secrets = {
    "cloudflare-api-key" = {};
  };

  # inspo: https://carjorvaz.com/posts/setting-up-wildcard-lets-encrypt-certificates-on-nixos/
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin+acme@mantannest.com";

    certs."mantannest.com" = {
      domain = "mantannest.com";
      extraDomainNames = ["*.mantannest.com"];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      # inspo: https://go-acme.github.io/lego/dns/cloudflare/
      credentialFiles = {
        "CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare-api-key".path;
      };
    };
  };

  users.users.nginx.extraGroups = ["acme"];

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/acme"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
