{
  config.sops.secrets = {
    "headscale-preauth-key" = {};

    "alloy.env" = {
      restartUnits = ["alloy.service"];
    };
  };
}
