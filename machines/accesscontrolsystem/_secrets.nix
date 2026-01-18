{
  config.sops.secrets = {
    "cloudflare-api-key" = {};
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};
    "grafana-alloy-env" = {};

    "authentik-env" = {
      sopsFile = ./../../secrets/accesscontrolsystem-server.yaml;
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
