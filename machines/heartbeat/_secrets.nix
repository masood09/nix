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
      restartUnits = ["podman-babybuddy.service"];
    };

    "caddy-env" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
      owner = "caddy";
      restartUnits = ["caddy.service"];
    };

    "dell-idrac-fan-controller-env" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
      restartUnits = ["podman-dell-idrac-fan-controller.service"];
    };

    "garage-env" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
      restartUnits = ["garage.service"];
    };

    "grafana-authentik-client-secret" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
      owner = "grafana";
      restartUnits = ["grafana.service"];
    };

    "jobscraper-env" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
      restartUnits = ["podman-jobscraper.service"];
    };

    "karakeep-env" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
      owner = "karakeep";
      restartUnits = [
        "karakeep-web.service"
        "karakeep-workers.service"
      ];
    };

    "vaultwarden-env" = {
      sopsFile = ./../../secrets/heartbeat-server.yaml;
      restartUnits = ["vaultwarden.service"];
    };
  };
}
