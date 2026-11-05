# Options — Hermes Agent (Nous Research) headless gateway: model, web search,
# sandbox, ZFS.
{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        hermes = {
          enable = lib.mkEnableOption "Hermes Agent messaging gateway (Matrix/Discord/Telegram) with a podman-sandboxed terminal.";

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/hermes";
            description = "HERMES_HOME: config.yaml, memories, skills, sessions, cron jobs.";
          };

          userId = lib.mkOption {
            default = 3017;
            type = lib.types.ints.u16;
            description = "UID for the Hermes service user.";
          };

          groupId = lib.mkOption {
            default = 3017;
            type = lib.types.ints.u16;
            description = "GID for the Hermes service group.";
          };

          model = {
            baseUrl = lib.mkOption {
              type = lib.types.str;
              default = "https://ai.${config.networking.domain}/v1";
              description = "OpenAI-compatible endpoint (Strata on ixian by default).";
            };

            name = lib.mkOption {
              type = lib.types.str;
              default = "qwen3.8-flash-next-iq2_xs";
              description = "Model id as reported by the endpoint's /v1/models.";
            };
          };

          web = {
            searchBackend = lib.mkOption {
              type = lib.types.enum [
                ""
                "searxng"
                "firecrawl"
                "brave-free"
                "ddgs"
                "tavily"
                "perplexity"
                "keenable"
                "exa"
                "parallel"
                "xai"
                "nous"
              ];
              default = "";
              description = "web.search_backend in config.yaml. Empty leaves Hermes' own stored selection and autodetect in charge; the managed key is written either way, so clearing this clears the key too and does not leave a stale backend pointing at an unset URL. SearXNG is search-only, so web_extract resolves its own backend.";
            };

            searxngUrl = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "SEARXNG_URL. Empty resolves through the SearXNG module's clientUrl — loopback in host mode, the WireGuard namespace address when SearXNG is confined to the VPN namespace — which the gateway can reach because web_search runs in the gateway process rather than in the sandbox.";
            };
          };

          sandbox = {
            image = lib.mkOption {
              type = lib.types.str;
              # renovate: datasource=docker depName=docker.io/nousresearch/hermes-sandbox
              default = "docker.io/nousresearch/hermes-sandbox:desktop";
              description = "Container image the agent's terminal tool runs commands in (rootless podman).";
            };

            subIdStart = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 1000000000;
              description = "First ID of both the subordinate UID range and the subordinate GID range (65536 each) for the hermes user's rootless podman user namespace.";
            };
          };

          zfs = zfsOpts {
            serviceName = "Hermes";
            dataset = "fpool/fast/services/hermes";
            properties = {
              recordsize = "16K";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
