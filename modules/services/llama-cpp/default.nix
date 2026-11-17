# llama.cpp — Gemma 4 E4B and its uncensored variant behind one
# OpenAI-compatible llama-server API (and llama-server's built-in web UI).
#
# Wraps the upstream nixpkgs `services.llama-cpp` module (DynamicUser,
# hardening, PrivateDevices = false for GPU access). The models are pinned
# fixed-output derivations in /nix/store, so there is no state to persist and
# no dataset or UID to manage.
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
# were chosen by a load test at the pinned context, which goes on the command
# line: instances inherit the router's flags, and the command line wins over
# the preset and over --fit's pick of the largest context that fits.
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
#
# Thinking is off: the models' template thinks when llama.cpp's Jinja path
# enables it, so `enable_thinking: false` goes to the template, and answers
# start straight away (one test answer: 84 tokens instead of 351).
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

  # One preset section per model; the section name is the API model id.
  modelsPreset =
    lib.mapAttrs (id: m: {
      model = "${pkgs.fetchurl {inherit (m) name url hash;}}";
      load-on-startup = lib.boolToString (id == cfg.defaultModel);
    })
    cfg.models;
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
