{
  config.sops.secrets = {
    "cloudflare-api-key" = {};
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};

    "restic-env" = {
      sopsFile = ./../../secrets/meshcontrol-server.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../secrets/meshcontrol-server.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../secrets/meshcontrol-server.yaml;
    };
  };
}
