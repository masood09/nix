# Homelab options — Gamescope Steam machine with a retained SSH admin account.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # The console account is defined once, in _users.nix, which also sets
  # homelab.desktop.gaming.user. It is not homelab.primaryUser: the primary
  # user here is the admin account used for SSH and sudo.
  gamingUser = config.homelab.desktop.gaming.user;
in {
  config = {
    environment = {
      systemPackages = with pkgs; [
        # AMD GPU/VRAM/process telemetry for Strata and gaming sessions.
        nvtopPackages.amd
        amdgpu_top
      ];

      persistence = {
        "/nix/persist" = {
          directories = [
            {
              directory = "/home/${gamingUser}";
              user = gamingUser;
              group = "users";
              mode = "0700";
            }
          ];
        };
      };
    };

    boot = {
      initrd = {
        luks = {
          devices = {
            # The model disk is unlocked after /nix is mounted, using a key
            # stored on the encrypted root filesystem. This keeps boot to one
            # passphrase while retaining independent LUKS volumes.
            cryptmodels = {
              crypttabExtraOpts = [
                "noauto"
              ];
            };
          };
        };
      };
    };

    homelab = {
      role = "htpc";
      purpose = "Gamescope Steam Gaming and AI Inference PC";
      isRootZFS = false;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "ixian";
        # NetworkManager, not WiFi: Steam Gaming Mode's network settings and
        # its first-run wizard talk to NetworkManager over D-Bus, and without
        # it the wizard's network step cannot complete.
        wireless_enable = true;
      };

      services = {
        # Ships journald logs to Loki and node metrics to Prometheus on
        # heartbeat via the shared alloy/.env endpoints.
        alloy = {
          enable = true;
        };

        # Qwen3.8-Flash-Next IQ3_XXS (served as qwen3.8-flash-next-iq3_xxs), 256K
        # context (the model's trained length, no rope scaling), one request
        # at a time, CPU picture reader, on 127.0.0.1:8916. Conversation
        # memory is upstream's default int8 (~13.7 KB/token, ~3.6 GB at 256K);
        # only the newest 32K is kept on the card (--kv-resident), the rest in
        # RAM. Strata answers any model name, so clients still asking for
        # qwen3.8-flash-next-iq2_xs keep working.
        #
        # Model choice, from benchmarks on 2026-11-16 (low effort; 13-prompt
        # chat set; prompts up to 200K tokens): IQ2_XS, IQ3_XXS and IQ3_S ran
        # at 32K-256K without swapping or low-RAM mode, and all scored 13/13
        # with and without the speed projection, so the set could not tell
        # them apart. The default is IQ3_XXS (moved off IQ3_S on 2026-11-28):
        # with quality indistinguishable it is the faster and lighter choice,
        # replying at 54 tok/s on short answers and ~60 on long ones (IQ3_S:
        # 44 and ~58) and leaving 9.3 GB of RAM free at 256K with a 200K-token
        # prompt (IQ3_S: 8.1 GB); every size reads prompts at ~1,800 tok/s.
        # IQ3_S, upstream's best-rated size ("matches the full model on the
        # published tests"), stays in models, so a request naming
        # qwen3.8-flash-next-iq3_s still gets it, for one model load. On IQ3_S
        # with the file cache down to ~9 GB, its first long prompt stalled
        # ~40 s on disk reads once; later ones read at full speed. Keep other
        # memory-hungry work off ixian while long conversations run. (The
        # 2026-11-04 note that IQ3_XXS swapped ~29 GB at 128K did not
        # reproduce.)
        # Qwen3.6-35B-A3B was tried and dropped: its engine keeps conversation
        # memory in fp32 on the card (~45 KB/token, no --kv), so 256K ran the
        # 16 GB RX 9070 out of memory at load.
        #
        # parallel stays 1: DFlash2 drafting (upstream's auto choice, not
        # pinned) only runs with one request at a time. Strata stays on
        # loopback with no vhost: clients reach it through model-router and
        # the LiteLLM gateway on mentat.
        strata = {
          enable = true;
          family = "qwen";
          model = "iq3_xxs";
          # Sizes model-router may switch to (each benchmarked at 256K on
          # 2026-11-16 without swapping). Each start regenerates whichever
          # sizes are stale, so a switch is one model load.
          models = ["iq2_xs" "iq3_xxs" "iq3_s"];
          context = "256k";
          parallel = 1;

          # Qwen3.8's template thinks at xhigh when a request names no effort,
          # and OpenCode names none. Measured on 2026-11-15 (two short
          # coding/Nix prompts): xhigh spent 1.4–2.6K tokens thinking, medium
          # 0.5–0.9K, and an explicit high ran away to 11K tokens (208 s) on a
          # two-sentence question. Low is the default for requests that name
          # none (the 2026-11-16 benchmark scored 13/13 at low on every size;
          # low caps thinking at 256 tokens of a 512 max_tokens, which was too
          # little to count records in a long document). Low is only an
          # instruction in the prompt ("keep your thinking brief"), not a
          # limit; the budget is the hard cap, at which Strata closes the
          # thinking and the model answers. 1024 covers low and medium (0.5–0.9K
          # measured) and stops a runaway in under a minute at ixian's ~20
          # tokens/s; 8192 let one think for about 7 minutes. A request can
          # still ask for medium or high, or set its own budget, which wins.
          settings = {
            reasoning_effort = "low";
            reasoning_budget_tokens = 1024;
            # The server's own limit on engine silence during a request
            # (default 300 s), separate from the engine watchdog in
            # extraLaunchArgs below. Matched to it so a long cold prefill is
            # not cut off by whichever limit is shorter.
            engine_silence_s = 900;
            # Stock by default: the projection vector stays loaded (below),
            # but only a request that asks for it gets it, e.g. model-router's
            # -uncensored names or "experimental_speed_projection": true. No
            # generated run config has a sampling block of its own, so this
            # top-level key replaces nothing.
            sampling = {
              experimental_speed_projection = false;
            };
          };

          # Upstream's refusal-direction control vector, loaded so it can be
          # used on demand: the model declines far fewer requests, at
          # 0.2-0.4% per token and some quality (upstream measured perplexity
          # +15% on code, on Q2_0; no difference showed on the 13-prompt set
          # on 2026-11-16, IQ2_XS to IQ3_S, but it still refused some
          # requests). settings.sampling above makes stock the default, so it
          # applies only to requests that set
          # "experimental_speed_projection": true (model-router's -uncensored
          # names do). Strata's web UI sends true unless its per-chat switch
          # is turned off.
          experimentalSpeedProjection = true;

          # The engine's hung-request watchdog (STRATA_WATCHDOG_S, code
          # default 60 s) kills the engine when a request makes no progress
          # for that long. A cold prefill of a long prompt trips it: on
          # 2026-11-19 a 146K-token prompt right after a gaming session (no
          # prompt cache) went silent for over 60 s and the engine shot
          # itself, then the client retried into the same wall. 300 s was
          # still too short: a 181K-token cold prefill ran at ~70 tok/s and
          # one chunk sat silent for over 140 s. Console-mode is not
          # debounced, so every TV-on blip forces such a cold start; 900 s
          # lets it finish while a real GPU hang is still caught.
          extraLaunchArgs = [
            "--set"
            "STRATA_WATCHDOG_S=900"
          ];

          # Strata and the Steam session never share the GPU (~15 GB of VRAM):
          # console-mode below holds Strata while gaming.

          # Upstream ships engine releases every few days, at 04:30; a held
          # Strata skips that day's update.
          #
          # TECH DEBT: off since 2026-11-23. Control 0.1.66 answers 404 to any
          # model name but the loaded one, and model-router forwards its
          # -uncensored names to Strata unchanged, so heavy-uncensored broke
          # the morning it auto-updated. The engine and Control are pinned
          # back at 0.1.64 by hand on ixian. Re-enable once model-router
          # rewrites "model" to the name Strata serves.
          autoUpdate = {
            enable = false;
          };
        };

        # OpenAI-compatible proxy on :8922 that switches Strata's size from
        # each request's model name (qwen3.8-flash-next-<size>, and
        # <size>-uncensored for the speed projection). See
        # modules/services/model-router. Reached by LiteLLM on mentat over the
        # tailnet: the port is open on tailscale0 only (the Headscale ACL
        # limits it to mentat), and requests need the shared backend key.
        model-router = {
          enable = true;
          listenAddress = "0.0.0.0";
          clientTokensFile = config.sops.secrets."llm/backend-key".path;
          openFirewall = true;
          firewallInterfaces = ["tailscale0"];
        };

        # Gaming vs inference, following binary_sensor.ixian_gaming in Home
        # Assistant (a template helper defined in its UI: the TV on its HDMI
        # input, with the FancyLED sync box on HDMI 3, which is ixian).
        # Gaming holds and stops Strata and runs the Steam session; inference
        # (after 2 min off) stops the session and starts Strata. If Home
        # Assistant cannot be read, the mode stays as it is. See
        # modules/services/console-mode.
        console-mode = {
          enable = true;
          # ixian suspends shortly after game mode ends (_suspend.nix), so
          # loading the model in between would be wasted.
          startStrataAfterGaming = false;
          homeAssistant = {
            headerFile = config.sops.templates."console-mode-ha.header".path;
          };
        };

        # ixian sits inside 10.0.30.0/24, which jumpbox-home advertises as a
        # subnet route. Accepting it would send replies to LAN clients into
        # the tunnel, cutting ixian off from its own LAN. Matches the module
        # default; kept explicit so it isn't flipped without this context.
        tailscale = {
          enable = true;
          acceptRoutes = false;
        };
      };

      # Install the AMD graphics/compute driver stack for the Steam/Gamescope
      # console without enabling a general-purpose desktop shell.
      hardware = {
        audio = {
          enable = true;
        };

        graphics = {
          enable = true;
          driver = "amd";
        };
      };

      desktop = {
        # ixian is a dedicated Steam/Gamescope console, not a general-purpose
        # desktop. Keep the shared desktop bundle disabled so Flatpak, CUPS,
        # Thunar/GVFS, accounts-daemon, and desktop shells are not installed.
        enable = false;

        gaming = {
          enable = true;
        };

        shell = "none";

        niri = {
          enable = false;
        };
      };
    };

    # Boot straight into Steam Gaming Mode as the console account (gamingUser,
    # whose name is set by homelab.desktop.gaming.user in _users.nix). Jovian's
    # autoStart uses SDDM autologin with relogin, so if Steam or gamescope
    # exits or crashes the session starts again instead of leaving a blank
    # screen.
    jovian = {
      steam = {
        enable = true;
        autoStart = true;
        user = gamingUser;
        # No desktop session on this console: "Switch to Desktop" relaunches
        # Gaming Mode.
        desktopSession = "gamescope-wayland";

        # programs.steam only hands extraCompatPackages (Proton-GE, from
        # _gaming.nix) to Steam through its own package's wrapper, but
        # Jovian's steam-launcher runs a different steam build, so Gaming
        # Mode never saw Proton-GE: its compat log registered no such
        # tool, and a shortcut mapped to GE-Proton started the .exe with no
        # Proton at all. This file is the launcher's EnvironmentFile.
        environment = {
          STEAM_EXTRA_COMPAT_TOOLS_PATHS =
            lib.makeSearchPathOutput "steamcompattool" "" config.programs.steam.extraCompatPackages;

          # GE-Proton only (Valve's Proton ignores it): upgrades a game's FSR
          # 3.1 to FSR 4, the RDNA 4 machine-learning upscaler this GPU has.
          # Session-wide because gamectl's tiles launch through GE without
          # Steam's per-game launch options. GE does not ship AMD's
          # amdxcffx64.dll: at each launch it reads a manifest from
          # loathingkernel.github.io/proton-upscalers and downloads the DLL
          # into the prefix, so a first launch offline falls back to FSR 3.1.
          PROTON_FSR4_UPGRADE = "1";
        };
      };

      hardware = {
        has = {
          amd = {
            gpu = true;
          };
        };
      };

      steamos = {
        # SteamOS defaults are tuned for the Steam Deck. Its kernel
        # parameters (amd_iommu=off, ttm.pages_min, …) are Deck-specific, and
        # earlyoom would pick off Strata's ~47 GB resident model or a game
        # under memory pressure. Bluetooth, sysctl, zram, CEC, and automount
        # defaults stay on.
        enableDefaultCmdlineConfig = false;
        enableEarlyOOM = false;
      };
    };

    # ixian deliberately runs the release-26.05 Stylix and Home Manager
    # branches on nixos-unstable (Jovian requires unstable), so their release
    # checks would warn on every build.
    home-manager = {
      sharedModules = [
        {
          home = {
            enableNixpkgsReleaseCheck = false;
          };
        }
      ];
    };

    # Stylix release-26.05's kmscon target writes options nixos-unstable has
    # removed (services.kmscon.extraConfig/fonts). ixian runs no kmscon.
    stylix = {
      enableReleaseChecks = false;

      targets = {
        kmscon = {
          enable = false;
        };
      };
    };

    services = {
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse = {
          enable = true;
        };
      };
    };

    security = {
      rtkit = {
        enable = true;
      };
    };

    xdg = {
      # Steam/Gamescope does not need the desktop MIME database. The explicit
      # force resolves the conflict between the Steam session default and the
      # server-style Stylix closure hygiene used by the htpc role.
      icons = {
        enable = lib.mkForce false;
      };
      mime = {
        enable = lib.mkForce false;
      };
      sounds = {
        enable = lib.mkForce false;
      };
    };

    systemd = {
      # Suspend policy (who may suspend, and what wakes ixian) lives in
      # _suspend.nix.
      services = {
        cryptmodels-unlock = {
          description = "Unlock ixian model storage from the root-resident key";
          wantedBy = [
            "srv-models.mount"
          ];
          before = [
            "srv-models.mount"
          ];
          after = [
            "nix.mount"
          ];
          requires = [
            "nix.mount"
          ];
          path = [
            pkgs.cryptsetup
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            if cryptsetup status cryptmodels >/dev/null 2>&1; then
              exit 0
            fi

            cryptsetup open \
              --key-file /nix/secret/ixian-models.key \
              /dev/disk/by-partlabel/disk-models-models \
              cryptmodels
          '';
        };
      };
    };
  };
}
