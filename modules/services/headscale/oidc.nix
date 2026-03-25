# Headscale sub-module — OIDC integration with Authentik for VPN login.
{
  config,
  lib,
  ...
}: let
  headscaleCfg = config.homelab.services.headscale;
  cfg = headscaleCfg.oidc;
in {
  config = lib.mkIf (headscaleCfg.enable && cfg.enable) {
    services = {
      headscale = {
        settings = {
          oidc = {
            inherit (cfg) issuer;

            client_id = cfg.clientId;
            client_secret_path = config.sops.secrets."headscale/oidc-client-secret".path;

            only_start_if_oidc_is_available = true;
            # Authentik is the sole OIDC provider and always verifies email
            # before account creation, so a second check here is redundant.
            email_verified_required = false;

            scope = [
              "openid"
              "profile"
              "email"
              "custom"
            ];

            pkce = {
              enabled = true;
              method = "S256";
            };
          };
        };
      };
    };
  };
}
