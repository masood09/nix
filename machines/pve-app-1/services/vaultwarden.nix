{config, ...}: let
  domain = "mantannest.com";
  vaultwardenDomain = "https://passwords.${domain}";
  listenAddress = "0.0.0.0";
  listenPort = 8222;
in {
  sops.secrets = {
    "vaultwarden-env" = {
      owner = "vaultwarden";
      sopsFile = ./../../../secrets/pve-app-1.yaml;
    };
  };

  services = {
    vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      environmentFile = config.sops.secrets."vaultwarden-env".path;

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
