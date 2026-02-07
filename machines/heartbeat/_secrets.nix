{
  config.sops.secrets = {
    "alloy.env" = {
      restartUnits = ["alloy.service"];
    };

    "caddy.env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "caddy";
      restartUnits = ["caddy.service"];
    };

    "cloudflare-api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "dell-idrac-fan-controller.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-dell-idrac-fan-controller.service"];
    };

    "dpool_tank_key" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "discord-zfs-webhook" = {};

    "fpool_fast_key" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "headscale-preauth.key" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "grafana-authentik-client-secret" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "grafana";
      restartUnits = ["grafana.service"];
    };

    "jobscraper.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-jobscraper.service"];
    };

    "karakeep.env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "karakeep";
      restartUnits = [
        "karakeep-web.service"
        "karakeep-workers.service"
      ];
    };

    "opencloud-collabora.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-compose-opencloud-root.target"];
    };

    "opencloud-opencloud.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-compose-opencloud-root.target"];
    };

    "restic.env" = {
      sopsFile = ./secrets.sops.yaml;
    };
    "restic-repo" = {
      sopsFile = ./secrets.sops.yaml;
    };
    "restic-password" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "vaultwarden.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["vaultwarden.service"];
    };
  };
}
