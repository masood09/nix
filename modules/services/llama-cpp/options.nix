# Options — llama.cpp router serving Gemma 4 E4B and its uncensored variant
# (listen address, models, context, KV cache).
{lib, ...}: let
  modelType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "File name of the GGUF in the Nix store (fetchurl's name).";
      };

      url = lib.mkOption {
        type = lib.types.str;
        description = "Download URL of the GGUF, pinned to a repository revision.";
      };

      hash = lib.mkOption {
        type = lib.types.str;
        description = "SRI hash of the GGUF.";
      };
    };
  };
in {
  options = {
    homelab = {
      services = {
        llama-cpp = {
          enable = lib.mkEnableOption "llama.cpp router serving local chat models on the GPU.";

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = ''
              Address llama-server listens on. Loopback by default. Any other
              address requires apiKeyFile, since the API is otherwise open.
            '';
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8921;
            description = "Port llama-server listens on (see docs/service-registry.org).";
          };

          apiKeyFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = lib.literalExpression ''config.sops.secrets."llm/backend-key".path'';
            description = ''
              File of API keys, one per line (llama-server --api-key-file).
              Requests must then send one as a Bearer token; /health stays
              open. It must be readable by the llama-cpp user.
            '';
          };

          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to open listenPort in the firewall.";
          };

          firewallInterfaces = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["tailscale0"];
            description = "Interfaces to open listenPort on. Empty means every interface.";
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3022;
            description = "UID of the llama-cpp service user (see docs/service-registry.org).";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3022;
            description = "GID of the llama-cpp service group.";
          };

          models = lib.mkOption {
            type = lib.types.attrsOf modelType;
            default = {
              gemma-4-e4b = {
                name = "gemma-4-E4B_q4_0-it.gguf";
                url = "https://huggingface.co/google/gemma-4-E4B-it-qat-q4_0-gguf/resolve/4b4a2c1d584be7264f87aac328a1bc739ce81b6c/gemma-4-E4B_q4_0-it.gguf";
                hash = "sha256-Z2w1Bw222+Uvk+nIZO4Puk7d6pS5yHXZyxDa/0U/uu4=";
              };
              gemma-4-e4b-uncensored = {
                name = "Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf";
                url = "https://huggingface.co/HauhauCS/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive/resolve/45b6a334b4bcd1d7f37179df58b3b1d66a184e5d/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf";
                hash = "sha256-BRRkKYcPTsTBaIL0S+wpxR5Hl0Y61wgARKXHSMq7JIY=";
              };
            };
            description = ''
              Models the router offers, keyed by API model id (the `model` a
              request names and the INI section name). Only one is loaded at a
              time (--models-max 1); a request for another swaps it in.
            '';
          };

          defaultModel = lib.mkOption {
            type = lib.types.str;
            default = "gemma-4-e4b";
            description = "Key of `models` loaded when the service starts.";
          };

          contextSize = lib.mkOption {
            type = lib.types.ints.positive;
            default = 32768;
            description = ''
              Context length in tokens, shared by every model and pinned on the
              command line (it wins over the preset and over --fit). At 32768 the
              P1000 measured 3419 MiB for gemma-4-e4b and 3618 MiB for
              gemma-4-e4b-uncensored; the models' native maximum is 131072.
            '';
          };

          device = lib.mkOption {
            type = lib.types.str;
            default = "Vulkan1";
            example = "CUDA0";
            description = ''
              llama.cpp offload device (`llama-server --list-devices`). On
              heartbeat, Vulkan0 is the Intel iGPU and Vulkan1 the Quadro P1000.
            '';
          };

          cacheType = lib.mkOption {
            type = lib.types.enum ["f16" "q8_0" "q4_0"];
            default = "f16";
            description = ''
              KV cache type for both K and V. f16 fits at the default 32k context;
              quantized types need flash attention, which the module enables.
            '';
          };

          extraFlags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Extra llama-server arguments, appended after the module's own (model instances inherit them).";
          };
        };
      };
    };
  };
}
