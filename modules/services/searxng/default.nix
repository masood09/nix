# SearXNG — private metasearch for the home network, the tailnet and AI
# agents (through the searxng MCP server behind LiteLLM, machines/mentat).
#
# No login: Caddy answers only allowedNetworks and returns 403 to everyone
# else, which keeps it off the open internet, where a SearXNG is soon used as
# a free search proxy and the engines block the home address. SearXNG's own
# rate limiter is off for the same reason (it needs Redis and only guards
# public instances). JSON output is on, which the MCP server searches with.
# Searches leave from the home connection.
#
# Engines: SearXNG scrapes result pages, which the engines keep changing and
# blocking, so it comes from nixpkgs-unstable, whose snapshot carries the
# newer engine fixes (stable's May 2026 one met CAPTCHAs from DuckDuckGo and
# Startpage and a suspension from Brave on its first searches). Google, Bing
# and Mojeek, off by default, are on next to the defaults (Brave,
# DuckDuckGo, Wikipedia, …), so a search still gets results while one engine
# blocks. With use_default_settings, these entries merge into the default
# engine list by name.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.searxng;
  caddyEnabled = config.services.caddy.enable;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.allowedNetworks != [];
        message = "homelab.services.searxng.allowedNetworks is the only gate in front of SearXNG; set it.";
      }
    ];

    services = {
      searx = {
        enable = true;
        package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.searxng;
        inherit (cfg) environmentFile;

        settings = {
          general = {
            instance_name = "Search";
          };

          server = {
            bind_address = "127.0.0.1";
            port = cfg.listenPort;
            base_url = "https://${cfg.webDomain}/";
            secret_key = "$SEARX_SECRET_KEY";
            limiter = false;
            public_instance = false;
            # Result images load through SearXNG, so the sites behind them
            # don't see the browser.
            image_proxy = true;
          };

          search = {
            formats = [
              "html"
              "json"
            ];
          };

          engines = [
            {
              name = "google";
              disabled = false;
            }
            {
              name = "bing";
              disabled = false;
            }
            {
              name = "mojeek";
              disabled = false;
              inactive = false;
            }
          ];
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              @allowed remote_ip ${lib.concatStringsSep " " cfg.allowedNetworks}
              handle @allowed {
                reverse_proxy http://127.0.0.1:${toString cfg.listenPort}
              }
              respond 403
            '';
          };
        };
      };
    };
  };
}
