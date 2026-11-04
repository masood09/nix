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
              default = "https://ai.${config.networking.domain}/v1";
              description = "OpenAI-compatible endpoint for tagging and summaries (Strata on ixian by default).";
            };

            model = lib.mkOption {
              type = lib.types.str;
              default = "qwen3.8-flash-next-iq2_xs";
              description = ''
                Model id as reported by the endpoint's /v1/models, used for both
                text and image inference (Strata's model reads pictures).
              '';
            };

            jobTimeoutSec = lib.mkOption {
              type = lib.types.ints.positive;
              default = 600;
              description = ''
                Seconds an inference job may run. Karakeep's default of 30 is
                too short for a local model that thinks before answering.
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
