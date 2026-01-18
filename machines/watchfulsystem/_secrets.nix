{
  config.sops.secrets = {
    "cloudflare-api-key" = {};
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};

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
