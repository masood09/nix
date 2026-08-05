# Sops secret declarations — paths, owners, and restart triggers for this machine.
{
  config = {
    sops = {
      secrets = {
        "alloy/.env" = {
          restartUnits = ["alloy.service"];
        };

        "authentik/.env" = {
          sopsFile = ./secrets.sops.yaml;
          restartUnits = [
            "authentik.service"
            "authentik-worker.service"
          ];
        };

        # authentik-nix's native services.authentik-ldap module — not a container, a
        # real Go binary from authentik-nix's own build (authentikComponents.gopkgs.ldap).
        # Content: AUTHENTIK_HOST=https://<webDomain>, AUTHENTIK_INSECURE=false,
        # AUTHENTIK_TOKEN=<outpost token, from Authentik's admin UI: Applications ->
        # Outposts -> Jellyfin LDAP Outpost -> View Deployment Info>.
        "authentik/ldap-outpost.env" = {
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["authentik-ldap.service"];
        };

        "cloudflare/api-key" = {
          restartUnits = ["acme-setup.service"];
        };

        "restic/.env" = {
          sopsFile = ./secrets.sops.yaml;
        };
        "restic/repo" = {
          sopsFile = ./secrets.sops.yaml;
        };
        "restic/password" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "tailscale/preauth-key" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "zed/discord-zfs-webhook" = {};
      };
    };
  };
}
