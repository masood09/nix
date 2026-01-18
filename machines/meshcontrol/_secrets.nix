{
  config.sops.secrets = {
    "cloudflare-api-key" = {};
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};

    "headscale-authentik-client-secret" = {
      owner = "headscale";
      sopsFile = ./../../secrets/meshcontrol-server.yaml;
    };

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
