# Options — SearXNG metasearch, for the home network, the tailnet and AI agents.
{
  config,
  lib,
  ...
}: {
  options = {
    homelab = {
      services = {
        searxng = {
          enable = lib.mkEnableOption "SearXNG metasearch";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "search.${config.networking.domain}";
            description = "Domain of the web UI and the search API, served by Caddy.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8930;
            description = "Loopback port of SearXNG behind Caddy (docs/service-registry.org).";
          };

          allowedNetworks = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["10.0.30.0/24" "100.64.0.0/10"];
            description = ''
              Client networks Caddy serves; every other address gets 403.
              There is no login, so this is the only gate: a SearXNG open to
              the internet is soon used as a free search proxy, and the
              engines then block the home address. Caddy sees real client
              addresses here (no tunnel or trusted proxy in front).
            '';
          };

          environmentFile = lib.mkOption {
            type = lib.types.str;
            description = "Environment file holding SEARX_SECRET_KEY=<random>, SearXNG's secret for cookies and tokens.";
          };
        };
      };
    };
  };
}
