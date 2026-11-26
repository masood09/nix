# Sops secret declarations — paths, owners, and restart triggers for this machine.
{config, ...}: {
  config = {
    sops = {
      secrets = {
        "user/password" = {
          sopsFile = ./secrets.sops.yaml;
          neededForUsers = true;
        };

        # OpenCode's LiteLLM virtual key (created in the LiteLLM UI, allowed
        # every model the gateway serves). OpenCode reads it as the user at
        # start, so it is owned by the primary user.
        "litellm/opencode-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = config.homelab.primaryUser.userName;
        };

        # Token of Grafana's read-only (Viewer) service account for AI
        # agents; mcp-grafana reads it as the user (grafana-mcp).
        "grafana/mcp-token" = {
          sopsFile = ./secrets.sops.yaml;
          owner = config.homelab.primaryUser.userName;
        };

        "zed/discord-zfs-webhook" = {};
      };
    };
  };
}
