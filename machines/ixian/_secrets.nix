# Sops secret declarations — paths, owners, and restart triggers for this machine.
{
  config = {
    sops = {
      secrets = {
        # Shared Cloudflare DNS token for the wildcard ACME certificate Caddy
        # serves ai.mantannest.com with.
        "cloudflare/api-key" = {
          restartUnits = ["acme-setup.service"];
        };

        "tailscale/preauth-key" = {
          sopsFile = ./secrets.sops.yaml;
        };
      };
    };
  };
}
