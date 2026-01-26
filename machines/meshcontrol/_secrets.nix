{
  config.sops.secrets = {
    "cloudflare-api-key" = {};
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};
    "grafana-alloy-env" = {};

    "headscale-authentik-client-secret" = {
      owner = "headscale";
      sopsFile = ./../../secrets/meshcontrol-server.yaml;
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
