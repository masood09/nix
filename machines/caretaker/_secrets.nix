{
  config.sops.secrets = {
    "alloy.env" = {
      restartUnits = ["alloy.service"];
    };

    "headscale-preauth.key" = {
      sopsFile = ./secrets.sops.yaml;
    };
  };
}
