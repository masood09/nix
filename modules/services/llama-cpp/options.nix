# Options — llama.cpp server running Gemma 4 E4B (listen address, context, KV cache).
{lib, ...}: {
  options = {
    homelab = {
      services = {
        llama-cpp = {
          enable = lib.mkEnableOption "llama.cpp server running Gemma 4 E4B on the local GPU.";

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address llama-server listens on. Loopback by default; there is no auth on the API.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8921;
            description = "Port llama-server listens on (see docs/service-registry.org).";
          };

          contextSize = lib.mkOption {
            type = lib.types.ints.positive;
            default = 32768;
            description = "Context length in tokens. 32768 measured at 3422 MiB on the P1000; the model's native maximum is 131072.";
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
            description = "Extra llama-server arguments, appended after the module's own.";
          };
        };
      };
    };
  };
}
