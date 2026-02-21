{
  config.sops.secrets = {
    "alloy/.env" = {
      restartUnits = ["alloy.service"];
    };

    "cloudflare/api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "headscale/dns-extra-records.json" = {
      owner = "headscale";
      sopsFile = ./../../secrets/headscale-dns.sops.yaml;
      restartUnits = ["headscale.service"];
    };

    "headscale/oidc-client-secret" = {
      owner = "headscale";
      sopsFile = ./secrets.sops.yaml;
      restartUnits = [
        "headscale.service"
        "headplane.service"
      ];
    };

    "headscale/headplane/headscale-api-key" = {
      owner = "headscale";
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["headplane.service"];
    };

    "headscale/headplane/integration-agent-pre-auth-key" = {
      owner = "headscale";
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["headplane.service"];
    };

    "headscale/headplane/server-cookie-secret" = {
      owner = "headscale";
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["headplane.service"];
    };

    "restic/.env" = {
      sopsFile = ./secrets.sops.yaml;
    };
    "restic/repo" = {
      sopsFile = ./secrets.sops.yaml;
    };
    "restic/password" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "tailscale/preauth-key" = {
      sopsFile = ./secrets.sops.yaml;
    };

    "zed/discord-zfs-webhook" = {};
  };
}
