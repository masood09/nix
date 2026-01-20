{
  config.sops.secrets = {
    "cloudflare-api-key" = {};
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};
    "grafana-alloy-env" = {};

    "dpool_tank_key" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
    };

    "fpool_fast_key" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
    };

    "restic-env" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
    };

    "babybuddy-env" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
    };

    "vaultwarden-env" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
    };
  };
}
