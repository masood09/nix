{
  config.sops.secrets = {
    "babybuddy-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-babybuddy.service"];
    };

    "cloudflare-api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};

    "grafana-alloy-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["alloy.service"];
    };

    "authentik-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = [
        "authentik.service"
        "authentik-worker.service"
      ];
    };

    "caddy-env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "caddy";
      restartUnits = ["caddy.service"];
    };

    "dpool_tank_key" = {
      sopsFile = ./secrets.sops.yaml;
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
  };
}
