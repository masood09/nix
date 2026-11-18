# Options — Karakeep bookmark manager (domain, port, ZFS, OAuth).
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
        karakeep = {
          enable = lib.mkEnableOption "Whether to enable Karakeep.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "keep.${config.networking.domain}";
            description = "Domain name for the Karakeep web interface.";
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/karakeep/";
            description = "Directory for Karakeep persistent data.";
          };

          listenPort = lib.mkOption {
            default = 8904;
            type = lib.types.port;
            description = "Port for the Karakeep web server.";
          };

          userId = lib.mkOption {
            default = 3007;
            type = lib.types.ints.u16;
            description = "UID for the Karakeep service user.";
          };

          groupId = lib.mkOption {
            default = 3007;
            type = lib.types.ints.u16;
            description = "GID for the Karakeep service group.";
          };

          openFirewall = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = "Whether to open the listen port in the firewall.";
          };

          inference = {
            baseUrl = lib.mkOption {
              type = lib.types.str;
              default = "https://llm.${config.networking.domain}/v1";
              description = ''
                OpenAI-compatible endpoint for tagging and summaries: the
                LiteLLM gateway on mentat. OPENAI_API_KEY in the sops .env is
                Karakeep's own LiteLLM virtual key.
              '';
            };

            model = lib.mkOption {
              type = lib.types.str;
              default = "light";
              description = ''
                Model used for both text and image inference. light is
                heartbeat's Gemma 4 E4B, which reads pictures (its vision
                projector runs on the CPU, ~10-15 s a photo); it runs 24/7 on
                the same host, so tagging never depends on ixian.
              '';
            };

            contextLength = lib.mkOption {
              type = lib.types.ints.positive;
              default = 8192;
              description = ''
                Tokens of page content Karakeep sends (INFERENCE_CONTEXT_LENGTH).
                With maxOutputTokens it must stay inside the model's context
                (light: 16384). On heartbeat's P1000 an 8K prompt reads in
                ~45-60 s.
              '';
            };

            maxOutputTokens = lib.mkOption {
              type = lib.types.ints.positive;
              default = 2048;
              description = "Largest completion Karakeep asks for (INFERENCE_MAX_OUTPUT_TOKENS); tags and summaries are short.";
            };

            jobTimeoutSec = lib.mkOption {
              type = lib.types.ints.positive;
              default = 600;
              description = ''
                Seconds an inference job may run. Karakeep's default of 30 is
                too short for a long article on heartbeat's GPU (prompts read at
                ~150-200 tok/s) or a photo encoded on the CPU.
              '';
            };
          };

          oauth = {
            providerHost = lib.mkOption {
              type = lib.types.str;
              default = "auth.${config.networking.domain}";
              description = "Hostname of the OAuth/OIDC provider.";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "karakeep";
              description = "OAuth client ID for Karakeep.";
            };
          };

          zfs = zfsOpts {
            serviceName = "Karakeep";
            dataset = "dpool/tank/services/karakeep";
            properties = {
              logbias = "latency";
              recordsize = "16K";
              primarycache = "all";
            };
          };
        };
      };
    };
  };
}
