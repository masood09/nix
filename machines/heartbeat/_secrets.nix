{
  config.sops.secrets = {
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};
    "grafana-alloy-env" = {};

    "dpool_tank_key" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
    };

    "fpool_fast_key" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
    };
  };
}
