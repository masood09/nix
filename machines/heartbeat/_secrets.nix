{
  config.sops.secrets = {
    "cloudflare-api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};

    "alloy.env" = {
      restartUnits = ["alloy.service"];
    };

    "dpool_tank_key" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "fpool_fast_key" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "restic-env" = {
      sopsFile = ./secrets.sops.yaml;
    };
    "restic-repo" = {
      sopsFile = ./secrets.sops.yaml;
    };
    "restic-password" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "babybuddy-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-babybuddy.service"];
    };

    "caddy-env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "caddy";
      restartUnits = ["caddy.service"];
    };

    "dell-idrac-fan-controller-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-dell-idrac-fan-controller.service"];
    };

    "garage-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["garage.service"];
    };

    "grafana-authentik-client-secret" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "grafana";
      restartUnits = ["grafana.service"];
    };

    "jobscraper-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-jobscraper.service"];
    };

    "karakeep-env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "karakeep";
      restartUnits = [
        "karakeep-web.service"
        "karakeep-workers.service"
      ];
    };

    "vaultwarden-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["vaultwarden.service"];
    };
  };
}
