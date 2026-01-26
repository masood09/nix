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
      sopsFile = ./../../secrets/accesscontrolsystem-server.yaml;
      restartUnits = [
        "authentik.service"
        "authentik-worker.service"
      ];
    };

    "restic-env" = {
      sopsFile = ./../../secrets/accesscontrolsystem-server.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../secrets/accesscontrolsystem-server.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../secrets/accesscontrolsystem-server.yaml;
    };
  };
}
