{
  config.sops.secrets = {
    "alloy.env" = {
      restartUnits = ["alloy.service"];
    };

    "cloudflare-api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "discord-zfs-webhook" = {};

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

    "headscale-preauth.key" = {};

    "restic.env" = {
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
