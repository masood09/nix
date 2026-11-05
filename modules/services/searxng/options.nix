# Options — SearXNG metasearch engine (domain, port, UID, VPN namespace, engines).
{
  config,
  lib,
  ...
}: {
  options = {
    homelab = {
      services = {
        searxng = {
          enable = lib.mkEnableOption "Whether to enable SearXNG, confined to the nixflix WireGuard namespace.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "search.${config.networking.domain}";
            description = "Domain name for the SearXNG web interface.";
          };

          listenPort = lib.mkOption {
            default = 8918;
            type = lib.types.port;
            description = "Port SearXNG listens on inside the VPN network namespace.";
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
            namespace = lib.mkOption {
              type = lib.types.str;
              default = config.nixflix.vpn.namespace;
              defaultText = lib.literalExpression "config.nixflix.vpn.namespace";
              description = "VPN-Confinement network namespace SearXNG is confined to.";
            };
          };

          # These are engine `name:` values from upstream searx/settings.yml,
          # matched exactly by `use_default_settings.engines.keep_only` — not
          # `!shortcuts`. The exit is a Proton P2P/datacenter IP, so the default
          # leaves out Google/Bing/DDG/Startpage, which tend to 403/CAPTCHA it.
          engines = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "brave"
              "mojeek"
              "qwant"
              "wikipedia"
              "wikidata"
              "github"
              "stackoverflow"
              "arxiv"
              "arch linux wiki"
              "nixos wiki"
              "mdn"
            ];
            description = "Upstream engine names to keep enabled; all other default engines are dropped.";
          };
        };
      };
    };
  };
}
