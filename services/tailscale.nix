{config, ...}: {
  sops.secrets = {
    "headscale-preauth-key" = {};
  };

  services.tailscale = {
    enable = false;
    authKeyFile = config.sops.secrets."headscale-preauth-key".path;
    extraUpFlags = [
      "--login-server=https://headscale.mantannest.com"
    ];
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/tailscale"
    ];
  };
}
