{config, ...}: {
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
}
