# Sops secret declarations — paths, owners, and restart triggers for this machine.
{config, ...}: {
  config = {
    sops = {
      secrets = {
        # Machine-specific login/sudo password for the admin account
        # (homelab.primaryUser), overriding the fleet-wide hash in
        # secrets/secrets.sops.yaml. A crypt hash (mkpasswd -m yescrypt).
        "user/password" = {
          sopsFile = ./secrets.sops.yaml;
          neededForUsers = true;
        };

        "alloy/.env" = {
          restartUnits = ["alloy.service"];
        };

        # Shared backend key (secrets/secrets.sops.yaml) that LiteLLM on
        # mentat sends; model-router refuses requests without it. One line, at
        # least 16 characters. Rotating it touches all three hosts.
        "llm/backend-key" = {
          owner = "model-router";
          restartUnits = ["model-router.service"];
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

      # Some of the repo's other templates live in _config.nix (navidrome) or
      # with their service. This one sits beside its secret because it
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
