# llama.cpp — Gemma 4 E4B chat model behind an OpenAI-compatible llama-server
# API (and llama-server's built-in web UI).
#
# Wraps the upstream nixpkgs `services.llama-cpp` module (DynamicUser,
# hardening, PrivateDevices = false for GPU access). The model is a pinned
# fixed-output derivation in /nix/store, so there is no state to persist and
# no dataset or UID to manage.
#
# Model choice (benchmarked on heartbeat 2026-11-16, eight models that fit the
# Quadro P1000's 4 GiB, 13 ChatGPT-style prompts with thinking off): Gemma 4
# E4B tied Qwen3.5-4B for the best score and made the least serious mistakes.
# It was the only model to decline a made-up novel instead of inventing its
# plot, and it got the multi-turn edit right where Qwen3.5-4B rewrote the plan.
# Gemma 4 E2B ran twice as fast in half the VRAM but hallucinated. Qwen3-4B-2507
# and Phi-4-mini could not fit a 16k f16 cache next to their weights.
#
# Thinking is off: the model's template thinks when llama.cpp's Jinja path
# enables it, so `enable_thinking: false` goes to the template, and answers
# start straight away (one test answer: 84 tokens instead of 351).
#
# Memory on the P1000: llama.cpp keeps the input layer, i.e. the large
# per-layer embedding tables of the E-series, on the CPU, so the GPU holds
# ~3.3 GiB of the 5.15 GB file. Most layers use a 512-token sliding window,
# so the f16 cache stays small: measured 3422 MiB in use at 32k. With that
# held, a concurrent Jellyfin NVENC transcode may fail to allocate. Accepted:
# transcoding on heartbeat is rare.
#
# Measured speed: decode 18 t/s (15.6 at 8k deep), prompt eval 239 t/s on a
# short prompt and 89 t/s at 8k deep. Cross-turn prefix reuse is automatic, so
# a follow-up turn pays only for its new tokens.
#
# Package: llama-cpp-vulkan from nixpkgs-unstable (0.9.0), substituted from
# cache.nixos.org; that is the build the model was tested on. Stable's 9190
# could not load the previous model (MiniCPM5) and is untested with Gemma 4.
#
# Backend: Vulkan. The legacy_580 NVIDIA ICD reports Vulkan 1.4 on Pascal,
# above llama.cpp's 1.2 floor. Vulkan also enumerates heartbeat's Intel UHD
# 630 iGPU first (Vulkan0, reporting host RAM as its memory), so --device
# pins the server to the P1000 (Vulkan1). A CUDA build is the fallback if
# Vulkan regresses: nixpkgs' cudaPackages is 12.9, which still targets sm_61.
# cudaCapabilities is a nixpkgs config setting, not a llama-cpp override
# argument, so take llama-cpp from a nixpkgs instance with
# config = { allowUnfree = true; cudaSupport = true; cudaCapabilities = ["6.1"]; }.
# That build is local (unfree, not cached).
#
# NVIDIA's Vulkan driver compiles shaders with a JIT that needs a writable +
# executable mapping, denied by the default W^X hardening (journal at start:
# "JIT session error: Permission denied"), so the unit below turns
# MemoryDenyWriteExecute off. A CUDA build would need the same.
#
# GPU access needs no unit override: heartbeat exposes no /dev/dri render
# node, and NVIDIA's /dev/nvidia* nodes are 0666.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.llama-cpp;

  llamaPackage = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llama-cpp-vulkan;

  # Google's QAT Q4_0 build, pinned to the repo commit that was benchmarked.
  model = pkgs.fetchurl {
    name = "gemma-4-E4B_q4_0-it.gguf";
    url = "https://huggingface.co/google/gemma-4-E4B-it-qat-q4_0-gguf/resolve/4b4a2c1d584be7264f87aac328a1bc739ce81b6c/gemma-4-E4B_q4_0-it.gguf";
    hash = "sha256-Z2w1Bw222+Uvk+nIZO4Puk7d6pS5yHXZyxDa/0U/uu4=";
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    services = {
      llama-cpp = {
        enable = true;
        package = llamaPackage;
        inherit model;
        host = cfg.listenAddress;
        port = cfg.listenPort;

        extraFlags =
          [
            # One slot, so the whole context belongs to one request.
            "--ctx-size"
            (toString cfg.contextSize)
            "--parallel"
            "1"

            # Weights and KV cache on the P1000 (not the iGPU).
            "--device"
            cfg.device
            "--n-gpu-layers"
            "99"
            "--flash-attn"
            "on"
            "--cache-type-k"
            cfg.cacheType
            "--cache-type-v"
            cfg.cacheType

            "--jinja"
            "--chat-template-kwargs"
            (builtins.toJSON {enable_thinking = false;})
            "--alias"
            "gemma-4-e4b"

            # Google's recommended sampling for Gemma 4.
            "--temp"
            "1.0"
            "--top-p"
            "0.95"
            "--top-k"
            "64"
          ]
          ++ cfg.extraFlags;
      };
    };

    systemd = {
      services = {
        llama-cpp = {
          # DynamicUser has HOME=/, so the NVIDIA driver's shader cache would
          # land on the read-only root and be disabled.
          environment = {
            XDG_CACHE_HOME = "/var/cache/llama-cpp";
          };

          serviceConfig = {
            # Needs the W^X exception: see the shader-JIT note in the header.
            MemoryDenyWriteExecute = lib.mkForce false;
          };
        };
      };
    };
  };
}
