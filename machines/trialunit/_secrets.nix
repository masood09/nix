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

    "authentik-env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = [
        "authentik.service"
        "authentik-worker.service"
      ];
    };

    "dpool_tank_key" = {
      sopsFile = ./secrets.sops.yaml;
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
