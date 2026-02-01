{
  config.sops.secrets = {
    "alloy.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["alloy.service"];
    };

    "authentik.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = [
        "authentik.service"
        "authentik-worker.service"
      ];
    };

    "babybuddy.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-babybuddy.service"];
    };

    "caddy-env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "caddy";
      restartUnits = ["caddy.service"];
    };

    "cloudflare-api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "dpool_tank_key" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "discord-zfs-webhook" = {};
    "headscale-preauth-key" = {};

    "garage-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["garage.service"];
    };

    "grafana-authentik-client-secret" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "grafana";
      restartUnits = ["grafana.service"];
    };

    "headscale-authentik-client-secret" = {
      owner = "headscale";
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["headscale.service"];
    };

    "headscale-extra-records.json" = {
      owner = "headscale";
      sopsFile = ./../../secrets/headscale-dns.sops.yaml;
      restartUnits = ["headscale.service"];
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

    "opencloud-collabora.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-compose-opencloud-root.target"];
    };

    "opencloud-opencloud.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-compose-opencloud-root.target"];
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

    "vaultwarden-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["vaultwarden.service"];
    };
  };
}
