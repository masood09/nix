{
  config.sops.secrets = {
    "alloy.env" = {
      restartUnits = ["alloy.service"];
    };

    "authentik.env" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = [
        "authentik.service"
        "authentik-worker.service"
      ];
    };

    "cloudflare-api-key" = {
      restartUnits = ["acme-setup.service"];
    };

    "discord-zfs-webhook" = {};

    "headscale-preauth.key" = {
      sopsFile = ./secrets.sops.yaml;
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
  };
}
