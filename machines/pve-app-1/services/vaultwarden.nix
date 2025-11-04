{ config, ... }: let
  domain = "mantannest.com";
  vaultwardenDomain = "https://passwords.${domain}";
  listenAddress = "0.0.0.0";
  listenPort = 8222;
in {
  sops.secrets = {
    "vaultwarden-env-file" = {
      owner = "vaultwarden";
      sopsFile = ./../../../secrets/vaultwarden-env;
      format = "binary";
    };
  };

  services = {
    vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      environmentFile = config.sops.secrets."vaultwarden-env-file".path;

      config = {
        DOMAIN = vaultwardenDomain;
        ROCKET_ADDRESS = listenAddress;
        ROCKET_PORT = listenPort;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [listenPort];

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/vaultwarden"
    ];
  };
}
