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
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["headscale.service"];
    };

    "headscale-extra-records.json" = {
      owner = "headscale";
      sopsFile = ./../../secrets/headscale-dns.sops.yaml;
      restartUnits = ["headscale.service"];
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
