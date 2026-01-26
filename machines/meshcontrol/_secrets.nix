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

    "headscale-authentik-client-secret" = {
      owner = "headscale";
      sopsFile = ./../../secrets/meshcontrol-server.yaml;
      restartUnits = ["headscale.service"];
    };

    "headscale-extra-records.json" = {
      owner = "headscale";
      sopsFile = ./../../secrets/headscale-dns.yaml;
      restartUnits = ["headscale.service"];
    };

    "restic-env" = {
      sopsFile = ./../../secrets/meshcontrol-server.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../secrets/meshcontrol-server.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../secrets/meshcontrol-server.yaml;
    };
  };
}
