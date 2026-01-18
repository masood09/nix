{
  config.sops.secrets = {
    "cloudflare-api-key" = {};
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};
    "grafana-alloy-env" = {};

    "restic-env" = {
      sopsFile = ./../../secrets/watchfulsystem-server.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../secrets/watchfulsystem-server.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../secrets/watchfulsystem-server.yaml;
    };
  };
}
