# Sops secret declarations — paths, owners, and restart triggers for this machine.
{config, ...}: {
  config = {
    sops = {
      secrets = {
        "alloy/.env" = {
          restartUnits = ["alloy.service"];
        };

        # Shared Cloudflare DNS token for the wildcard ACME certificate Caddy
        # serves ai.mantannest.com with.
        "cloudflare/api-key" = {
          restartUnits = ["acme-setup.service"];
        };

        "tailscale/preauth-key" = {
          sopsFile = ./secrets.sops.yaml;
        };

        # Long-lived token of the non-admin "ixian" Home Assistant user, read
        # only by console-mode through the template below. Stays root-only.
        "console-mode/ha-token" = {
          sopsFile = ./secrets.sops.yaml;
        };
      };

      # The repo's other templates live with their service (searxng) or in
      # _config.nix (navidrome). This one sits beside its secret because it
      # only wraps it in the header line curl reads with -H @file; the bare
      # token would not be a valid header.
      templates = {
        "console-mode-ha.header" = {
          content = ''
            Authorization: Bearer ${config.sops.placeholder."console-mode/ha-token"}
          '';
          owner = "console-mode";
          group = "console-mode";
          mode = "0400";
          restartUnits = ["console-mode.service"];
        };
      };
    };
  };
}
