# Homelab options — secondary DNS (Blocky + Unbound) and the LiteLLM gateway.
{
  config,
  lib,
  ...
}: {
  config = {
    homelab = {
      purpose = "Secondary DNS (DNS Filtering) & LiteLLM gateway";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "mentat";
      };

      programs = {
        fastfetch = {
          zpools = ["rpool"];
        };
      };

      services = {
        # The wildcard certificate Caddy serves llm.mantannest.com with.
        acme = {
          zfs = {
            enable = true;
          };
        };

        # Disabled: Blocky's config is fully declarative, tailscale's node
        # state is re-creatable, and LiteLLM's state lives in heartbeat's
        # Postgres (backed up there). Enable (with restic secrets) if mentat
        # ever holds state of its own.
        backup = {
          enable = false;
        };

        # Same setup as caretaker (primary): listen on :53, Unbound upstream.
        blocky = {
          enable = true;
        };

        caddy = {
          enable = true;
        };

        # Gateway for ixian (heavy) and heartbeat (light, 24/7), reached over
        # the tailnet with the shared backend key. heavy falls back to light
        # while ixian is gaming (model-router then answers 503 at once). See
        # modules/services/litellm.
        litellm = {
          enable = true;
          environmentFile = config.sops.templates."litellm.env".path;
          backends = {
            ixian = {
              apiBase = "http://ixian.dns.headscale.mantannest.com:8922/v1";
              models = lib.concatMap (size: [
                "qwen3.8-flash-next-${size}"
                "qwen3.8-flash-next-${size}-uncensored"
              ]) ["iq2_xs" "iq3_xxs" "iq3_s"];
              # Strata runs every size at 256K. Qwen thinks, so reasoning
              # counts against output; 32K is Qwen's recommended length.
              contextLength = 262144;
              maxOutputTokens = 32768;
              # Shadow pricing: the local quants are based on Qwen3.8 Flash
              # Next, and Alibaba's first-party API lists it at $0.15/M input,
              # $0.47/M output (LiteLLM's dashscope/qwen3.8-flash entry,
              # checked 2026-11). The spend dashboard compares against this.
              pricing = {
                inputCostPerToken = 1.5e-7;
                outputCostPerToken = 4.7e-7;
              };
            };
            heartbeat = {
              apiBase = "http://heartbeat.dns.headscale.mantannest.com:8921/v1";
              models = [
                "gemma-4-e4b"
                "gemma-4-e4b-uncensored"
              ];
              # llama.cpp's --ctx-size on heartbeat (homelab.services.llama-cpp).
              contextLength = 16384;
              maxOutputTokens = 8192;
              # Shadow pricing: Google's API serves Gemma 4 free of charge, so
              # price against the hosted rate LiteLLM tracks (DeepInfra's
              # gemma-4-E4B-it: $0.02/M input, $0.10/M output, checked 2026-11).
              pricing = {
                inputCostPerToken = 2.0e-8;
                outputCostPerToken = 1.0e-7;
              };
            };
          };
          aliases = {
            heavy = "qwen3.8-flash-next-iq3_s";
            heavy-uncensored = "qwen3.8-flash-next-iq3_s-uncensored";
            light = "gemma-4-e4b";
            light-uncensored = "gemma-4-e4b-uncensored";
          };
          fallbacks = {
            heavy = ["light"];
            heavy-uncensored = ["light-uncensored"];
          };
          # Authentik app litellm (infra-tofu), limited to homelab-admins, who
          # are LiteLLM's proxy_admins. Clients use keys, not the UI.
          authentik = {
            enable = true;
            adminGroup = "homelab-admins";
          };
        };

        # The image store is on ZFS, so a reboot (root rollback) does not pull
        # the LiteLLM image again. mentat has only rpool.
        podman = {
          enable = true;

          zfs = {
            enable = true;
            dataset = "rpool/root/var/lib/containers";
          };
        };

        # Bare-metal host with a single NVMe: per-disk SMART health. No BMC, so
        # no IPMI exporter here.
        smartctl-exporter = {
          enable = true;
        };

        tailscale = {
          enable = true;

          zfs = {
            enable = true;
          };
        };
      };
    };

    security = {
      acme = {
        certs = {
          # mentat sits on the VLAN whose port-53 traffic the LAN firewall
          # redirects to the internal resolvers (it is one of them), so lego's
          # direct check against Cloudflare's nameservers cannot be trusted
          # from here. Wait a fixed time instead, as ixian does; Let's Encrypt
          # validates from the public internet.
          ${config.networking.domain} = {
            extraLegoFlags = [
              "--dns.propagation-wait=60s"
            ];
          };
        };
      };
    };
  };
}
