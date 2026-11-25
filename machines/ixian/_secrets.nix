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

        # SteamGridDB API key (one line, from steamgriddb.com > Preferences
        # > API) that `gamectl art` uses to fetch tile art. Owned by the
        # console account, because gamectl re-execs as it before running.
        "gamectl/steamgriddb-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = config.homelab.desktop.gaming.user;
        };

        # Full URL of the Home Assistant webhook that controller-wake POSTs
        # to on the controller gesture (connect, Start, Home), on one line:
        # https://home.<domain>/api/webhook/<id>. Root-only; the unit reads
        # it through LoadCredential. See _controller-wake.nix.
        "controller-wake/webhook-url" = {
          sopsFile = ./secrets.sops.yaml;
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
