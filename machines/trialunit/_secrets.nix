{
  config.sops.secrets = {
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};

    "grafana-alloy-env" = {
      restartUnits = ["alloy.service"];
    };

    "dpool_tank_key" = {
      sopsFile = ./../../secrets/trialunit-server.yaml;
    };
  };
}
