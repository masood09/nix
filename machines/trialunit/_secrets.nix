{
  config.sops.secrets = {
    "cloudflare-api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};

    "grafana-alloy-env" = {
      restartUnits = ["alloy.service"];
    };

    "dpool_tank_key" = {
      sopsFile = ./../../secrets/trialunit-server.yaml;
    };

    "opencloud-collabora.env" = {
      sopsFile = ./../../secrets/trialunit-server.yaml;
    };

    "opencloud-opencloud.env" = {
      sopsFile = ./../../secrets/trialunit-server.yaml;
    };
  };
}
