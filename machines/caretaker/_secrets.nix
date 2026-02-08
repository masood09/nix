{
  config.sops.secrets = {
    "alloy.env" = {
      restartUnits = ["alloy.service"];
    };

    "tailscale/preauth.key" = {
      sopsFile = ./secrets.sops.yaml;
    };
  };
}
