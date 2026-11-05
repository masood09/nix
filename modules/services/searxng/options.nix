# Options — SearXNG metasearch engine (domain, port, UID, VPN mode, engines).
{
  config,
  lib,
  ...
}: let
  self = config.homelab.services.searxng;

  # The address a client on this host reaches SearXNG on. In VPN mode the netns
  # DNAT rules are PREROUTING-only, so loopback does not work there and the
  # namespace address is the only one a host process can connect to.
  hostAddress =
    if self.vpn.enable
    then config.vpnNamespaces.${self.vpn.namespace}.namespaceAddress
    else "127.0.0.1";
in {
  options = {
    homelab = {
      services = {
        searxng = {
          enable = lib.mkEnableOption "Whether to enable SearXNG behind Caddy.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "search.${config.networking.domain}";
            description = "Domain name for the SearXNG web interface.";
          };

          listenPort = lib.mkOption {
            default = 8918;
            type = lib.types.port;
            description = "Port SearXNG listens on (loopback, or inside the VPN namespace in VPN mode).";
          };

          clientUrl = lib.mkOption {
            type = lib.types.str;
            default = "http://${hostAddress}:${toString self.listenPort}";
            description = "URL a client on this host uses to reach SearXNG — Caddy's upstream target, and Hermes' SEARXNG_URL. Loopback with host egress, the WireGuard namespace address when vpn.enable is set.";
          };

          limiter = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "SearXNG's request limiter (server.limiter). When false no limiter is applied at all, and botdetection's header filters stop rejecting clients that do not look like a browser — which is what a programmatic client such as Hermes' SearXNG provider needs, since it sends only Accept: application/json. The narrower alternative is botdetection.ip_lists.pass_ip, checked before those filters, which exempts one client address rather than every client.";
          };

          userId = lib.mkOption {
            default = 3018;
            type = lib.types.ints.u16;
            description = "UID for the searx service user (also runs the redis-searx Valkey instance).";
          };

          groupId = lib.mkOption {
            default = 3018;
            type = lib.types.ints.u16;
            description = "GID for the searx service group.";
          };

          vpn = {
            enable = lib.mkEnableOption ''
              confining SearXNG to the nixflix WireGuard namespace, so all of its
              egress leaves through the VPN. Requires nixflix.vpn.enable. Off by
              default because many engines block shared VPN exits; VPN mode uses
              the separate `vpnEngines` list'';

            namespace = lib.mkOption {
              type = lib.types.str;
              default = config.nixflix.vpn.namespace;
              defaultText = lib.literalExpression "config.nixflix.vpn.namespace";
              description = "VPN-Confinement network namespace SearXNG is confined to when vpn.enable is set.";
            };
          };

          # Both engine lists hold engine `name:` values from upstream
          # searx/settings.yml, matched exactly by
          # `use_default_settings.engines.keep_only` — not `!shortcuts`. Every
          # listed engine is also force-enabled. Re-check dotted names (e.g.
          # brave.images) when the searxng package pin moves.
          #
          # Left out of both: yandex images (upstream parser fails with a JSON
          # error) and deviantart (returns 0 results).
          engines = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              # General web
              "google"
              "bing"
              "brave"
              "duckduckgo"
              "startpage"
              "qwant"
              "mojeek"
              "yahoo"
              "yandex"
              "wikipedia"
              "wikidata"

              # IT and docs
              "github"
              "stackoverflow"
              "arxiv"
              "arch linux wiki"
              "nixos wiki"
              "mdn"

              # Images
              "google images"
              "bing images"
              "duckduckgo images"
              "brave.images"
              "qwant images"
              "flickr"
              "openverse"
              "unsplash"
              "wikicommons.images"

              # Videos
              "google videos"
              "youtube"
              "bing videos"
              "duckduckgo videos"
              "brave.videos"
              "qwant videos"
              "vimeo"
              "dailymotion"
              "sepiasearch"
              "wikicommons.videos"
            ];
            description = "Engines used with host egress (vpn.enable = false): upstream names to keep and force-enable; all other default engines are dropped.";
          };

          # Tested through SearXNG from the shared Proton P2P exit (2026-11-05).
          # Left out because they fail there: brave, duckduckgo and yahoo
          # (rate-limit, deny or disconnect); google, startpage and mojeek
          # (CAPTCHAs); qwant, openverse and vimeo (403); unsplash (redirect);
          # wikidata (403 during engine init, so it never registers).
          vpnEngines = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              # General web
              "yandex"
              "wikipedia"

              # IT and docs
              "github"
              "stackoverflow"
              "arxiv"
              "arch linux wiki"
              "nixos wiki"
              "mdn"

              # Images
              "bing images"
              "flickr"
              "wikicommons.images"

              # Videos
              "youtube"
              "dailymotion"
              "sepiasearch"
              "bing videos"
              "wikicommons.videos"
            ];
            description = "Engines used when vpn.enable is set; same semantics as `engines`.";
          };
        };
      };
    };
  };
}
