# llama.cpp — Gemma 4 E4B (and its uncensored variant) and LFM3-1.7B behind
# one OpenAI-compatible llama-server API (and llama-server's built-in web UI).
#
# Wraps the upstream nixpkgs `services.llama-cpp` module (hardening,
# PrivateDevices = false for GPU access), with a static user instead of its
# DynamicUser (see below). The models and projectors are pinned fixed-output
# derivations in /nix/store, so there is no state to persist and no dataset.
#
# Router mode: llama-server starts with no model and a preset INI listing
# every entry of `models`; each section name is an API model id. A request
# names its model, and the router starts that model as a child llama-server
# on an ephemeral loopback port and proxies to it. Requests in router mode must
# carry "model" ("model name is missing" otherwise); the web UI has a picker.
# Only one model fits the P1000's 4 GiB, so --models-max 1: a request for the
# other model queues; the busy one is never interrupted, it is evicted once its
# last request ends (10 s to stop gracefully; one still loading is killed at
# once), and then the queued model loads, ~25 s from the page cache. A queued
# request has no server-side timeout, but a client's own read timeout still
# applies during a swap. At startup the router also runs one short-lived child
# per model to measure its memory (log noise, a few seconds).
#
# Memory accounting is by count only (no --models-memory-margin), so a model
# that does not fit is loaded anyway and runs out of memory. The quantizations
# were chosen by a load test at the pinned context. The context and KV type
# are per-model preset section keys, not router command-line arguments: the
# command line would override every section (checked on b12110: a section's
# ctx-size starts its child at that n_ctx_slot with the router passing none).
#
# Models (benchmarked on heartbeat 2026-11-16, 13 ChatGPT-style prompts with
# thinking off, scored 0/0.5/1 each):
#   gemma-4-e4b             Google's QAT Q4_0 (rev 4b4a2c1d). Best of eight
#                           models that fit the card, 11.5/13: tied Qwen3.5-4B
#                           with the least serious mistakes, and the only one to
#                           decline a made-up novel instead of inventing it.
#                           3419 MiB VRAM at 32k; decode 18 t/s (15.6 at 8k
#                           deep), prompt eval 239 t/s (89 at 8k).
#   gemma-4-e4b-uncensored  HauhauCS's "Aggressive" abliteration of
#                           google/gemma-4-e4b-it (rev 45b6a334), Q4_K_P, the
#                           largest of its quants that fits. It refuses nothing,
#                           by choice. 10.5/13: it invented a plot for the
#                           made-up novel and rewrote a plan it was asked to
#                           keep. 3618 MiB VRAM and 3.5 GiB host RAM at 32k;
#                           decode 16.4 t/s (14.5 at 8k), prompt eval 194 t/s.
#   lfm3-1-7b               Liquid AI's tri-hybrid agent model (rev b3f2ae5d),
#                           Q4_K_M: their suite has it beating 4B-class models
#                           at tool use; so did ours (2026-11-18 suite: perfect
#                           single, two-step and schema-required tool calls,
#                           strict JSON, needle exact-quoted at 25K — but it
#                           invented the made-up novel the Gemma QAT declines,
#                           which is why it supplements and defaultModel stays
#                           Gemma).
#                           Decode 42-46 t/s, prefill 288-317 t/s (218 at 32K,
#                           138 at 100K deep); ~1.6 GiB VRAM at 64K ctx with
#                           q8_0 KV. Q8_0 measured identical suite quality but
#                           decodes at 29-31 t/s, so Q4_K_M stays for speed,
#                           not fit: Q8_0 OOMed at 128K only with f16 KV; a
#                           2026-11-18 probe loaded 256K of it (Q4_K_M too,
#                           all three at q8_0 KV) with the run peaking at
#                           3731 MiB.
#
# Thinking: the Gemmas' template thinks when llama.cpp's Jinja path enables
# it, so `enable_thinking: false` goes to the template, and answers start
# straight away (one test answer: 84 tokens instead of 351). LFM3's template
# thinks on by default instead, and llama.cpp splits that into
# `reasoning_content`, so answers arrive even with no flag set — but an
# unlimited thinking budget can exhaust a small max_tokens before any visible
# answer is written (checked 2026-11-18: 512-token requests came back with
# content empty and all tokens spent on thinking). Clients that want LFM3 to
# think need max_tokens >= 2048; llama.cpp's --reasoning-budget could cap
# this server-wide if that ever bites.
#
# Vision: both models carry their own projector (mmproj, ~945 MB f16, same
# repository revision), so requests may include images. The projector runs on
# the CPU (--no-mmproj-offload): its 593 MiB buffer does not fit on the P1000
# next to the model even at 16K context. Measured 2026-11-17 on a 1280 px
# photo: ~10 s to encode and read it, then ~17 tok/s, with sensible tags.
#
# Memory on the P1000: llama.cpp keeps the input layer, i.e. the large
# per-layer embedding tables of the E-series, on the CPU, so the GPU holds
# about 3.3-3.5 GiB of each ~5.2 GB file. Most layers use a 512-token sliding
# window, so the f16 cache stays small. With a model loaded, a concurrent
# Jellyfin NVENC transcode may fail to allocate. Accepted: transcoding on
# heartbeat is rare.
#
# Package: llama-cpp-vulkan from nixpkgs-unstable (0.9.0), substituted from
# cache.nixos.org; that is the build the models were tested on. Stable's 9190
# could not load the previous model (MiniCPM5) and is untested with Gemma 4.
#
# Upstream module API: this uses `modelsPreset` and `extraFlags` from the
# pinned nixos-26.05 module. The newer module (nixpkgs-unstable) replaced both
# with freeform `settings` (where `models-preset` is a path), so a nixpkgs bump
# that brings it in means porting both.
#
# Backend: Vulkan. The legacy_580 NVIDIA ICD reports Vulkan 1.4 on Pascal,
# above llama.cpp's 1.2 floor. Vulkan also enumerates heartbeat's Intel UHD
# 630 iGPU first (Vulkan0, reporting host RAM as its memory), so --device
# pins the models to the P1000 (Vulkan1). A CUDA build is the fallback if
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
#
# The unit runs as a static llama-cpp user instead of upstream's DynamicUser,
# only so it can own apiKeyFile: a dynamic UID cannot be the owner of a sops
# secret. Everything else in upstream's sandbox is kept. systemd moves the
# State/CacheDirectory out of /var/lib/private on its own when DynamicUser
# goes off.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.llama-cpp;

  llamaPackage = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llama-cpp-vulkan;

  fetchGguf = f: "${pkgs.fetchurl {inherit (f) name url hash;}}";

  # One preset section per model; the section name is the API model id. Preset
  # keys are llama-server arguments without their leading dashes, so a model
  # with a vision projector gets its own `mmproj` here. Context and KV type
  # ride in the section (verified on b12110: a section's ctx-size starts its
  # child at that n_ctx_slot): the router's command line overrides every
  # section, so per-model values have no other carrier and the router itself
  # must not pass those arguments.
  modelsPreset = lib.mapAttrs (id: m:
    {
      model = fetchGguf m;
      load-on-startup = lib.boolToString (id == cfg.defaultModel);
      # `or` does not substitute here: the submodule always carries these
      # keys, defaulted to null. Check for null explicitly (b12110 bit us:
      # a section with ctx-size = null spawns its child with an empty
      # --ctx-size and the load fails).
      ctx-size = toString (
        if m.contextSize == null
        then cfg.contextSize
        else m.contextSize
      );
      cache-type-k =
        if m.cacheType == null
        then cfg.cacheType
        else m.cacheType;
      cache-type-v =
        if m.cacheType == null
        then cfg.cacheType
        else m.cacheType;
    }
    // lib.optionalAttrs (m.mmproj != null) {
      mmproj = fetchGguf m.mmproj;
    })
  cfg.models;

  hasVision = lib.any (m: m.mmproj != null) (lib.attrValues cfg.models);
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.models ? ${cfg.defaultModel};
        message = "homelab.services.llama-cpp.defaultModel (${cfg.defaultModel}) must be one of homelab.services.llama-cpp.models: ${lib.concatStringsSep ", " (lib.attrNames cfg.models)}.";
      }
      {
        assertion = lib.elem cfg.listenAddress ["127.0.0.1" "::1" "localhost"] || cfg.apiKeyFile != null;
        message = "homelab.services.llama-cpp listens on ${cfg.listenAddress}: set apiKeyFile, or the API is open to that network.";
      }
    ];

    users = {
      users = {
        llama-cpp = {
          isSystemUser = true;
          group = "llama-cpp";
          uid = cfg.userId;
        };
      };

      groups = {
        llama-cpp = {
          gid = cfg.groupId;
        };
      };
    };

    networking = {
      firewall = lib.mkIf cfg.openFirewall (
        if cfg.firewallInterfaces == []
        then {
          allowedTCPPorts = [cfg.listenPort];
        }
        else {
          interfaces = lib.genAttrs cfg.firewallInterfaces (_: {
            allowedTCPPorts = [cfg.listenPort];
          });
        }
      );
    };

    services = {
      llama-cpp = {
        enable = true;
        package = llamaPackage;
        inherit modelsPreset;
        host = cfg.listenAddress;
        port = cfg.listenPort;

        # Model instances inherit these flags from the router.
        extraFlags =
          [
            # One model resident at a time: two do not fit the 4 GiB card.
            "--models-max"
            "1"

            # One slot, so the whole context belongs to one request.
            # (--ctx-size and --cache-type-k/v must NOT be added here: the
            # router's command line would override every preset section's
            # per-model values. They live in modelsPreset.)
            "--parallel"
            "1"

            # Weights and KV cache on the P1000 (not the iGPU).
            "--device"
            cfg.device
            "--n-gpu-layers"
            "99"
            "--flash-attn"
            "on"

            "--jinja"
            "--chat-template-kwargs"
            (builtins.toJSON {enable_thinking = false;})

            # Google's recommended sampling for Gemma 4.
            "--temp"
            "1.0"
            "--top-p"
            "0.95"
            "--top-k"
            "64"
          ]
          ++ lib.optionals (cfg.apiKeyFile != null) [
            "--api-key-file"
            cfg.apiKeyFile
          ]
          # The projector does not fit on the P1000 next to the model (see
          # mmprojOffload), so image encoding runs on the CPU.
          ++ lib.optionals (hasVision && !cfg.mmprojOffload) [
            "--no-mmproj-offload"
          ]
          ++ cfg.extraFlags;
      };
    };

    systemd = {
      services = {
        llama-cpp = {
          # The system user's HOME is /var/empty, so the NVIDIA driver's shader
          # cache would land on a read-only path and be disabled.
          environment = {
            XDG_CACHE_HOME = "/var/cache/llama-cpp";
          };

          serviceConfig = {
            # Needs the W^X exception: see the shader-JIT note in the header.
            MemoryDenyWriteExecute = lib.mkForce false;

            # Static user, so apiKeyFile can be owned by it (see header).
            DynamicUser = lib.mkForce false;
            User = "llama-cpp";
            Group = "llama-cpp";
          };
        };
      };
    };
  };
}
