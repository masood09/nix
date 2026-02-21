{
  config.sops.secrets = {
    "alloy/.env" = {
      restartUnits = ["alloy.service"];
    };

    "cloudflare/api-key" = {
      restartUnits = ["acme-setup.service"];
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
