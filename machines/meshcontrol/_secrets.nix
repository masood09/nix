{
  config.sops.secrets = {
    "alloy.env" = {
      restartUnits = ["alloy.service"];
    };

    "cloudflare-api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "discord-zfs-webhook" = {};

    "headscale/dns-extra-records.json" = {
      owner = "headscale";
      sopsFile = ./../../secrets/headscale-dns.sops.yaml;
      restartUnits = ["headscale.service"];
    };

    "headscale/oidc_client.secret" = {
      owner = "headscale";
      sopsFile = ./secrets.sops.yaml;
      restartUnits = [
        "headscale.service"
        "headplane.service"
      ];
    };

    "headscale/headplane/headscale_api.key" = {
      owner = "headscale";
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["headplane.service"];
    };

    "headscale/headplane/integration_agent_pre_auth.key" = {
      owner = "headscale";
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["headplane.service"];
    };

    "headscale/headplane/server_cookie.secret" = {
      owner = "headscale";
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["headplane.service"];
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

    "tailscale/preauth.key" = {
      sopsFile = ./secrets.sops.yaml;
    };
  };
}
