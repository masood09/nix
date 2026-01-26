{
  config.sops.secrets = {
    "headscale-preauth-key" = {};

    "grafana-alloy-env" = {
      restartUnits = ["alloy.service"];
    };
  };
}
