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
      sopsFile = ./secrets.sops.yaml;
    };

    "opencloud-collabora.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-compose-opencloud-root.service"];
    };

    "opencloud-opencloud.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["podman-compose-opencloud-root.service"];
    };
  };
}
