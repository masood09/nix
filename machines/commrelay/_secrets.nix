{
  config.sops.secrets = {
    "alloy.env" = {
      restartUnits = ["alloy.service"];
    };

    "cloudflare-api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "discord-zfs-webhook" = {};

    "matrix/lk-jwt-service/keys.key" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = ["lk-jwt-service.service"];
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
