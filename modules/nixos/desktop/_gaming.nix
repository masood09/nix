# Gaming — Steam, Gamescope, GameMode, and supporting tools.
# NixOS-level because Steam, GameMode, and Gamescope are system programs
# (capabilities, udev rules, firewall, 32-bit driver stack) rather than
# user-scoped Home Manager packages.
# GPU-specific tuning (GameMode DPM) is conditional on the graphics driver;
# Intel iGPUs lack the sysfs knobs that GameMode's GPU optimiser targets.
# Steam data lives in ~/.local/share/Steam/ inside /home, which is already
# persisted on both desktops — no additional impermanence config needed.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  gfxCfg = homelabCfg.hardware.graphics;
  isAmd = gfxCfg.driver == "amd";
in {
  options = {
    homelab = {
      desktop = {
        gaming = {
          enable = lib.mkEnableOption "Steam and gaming optimizations";
        };
      };
    };
  };

  config = lib.mkIf homelabCfg.desktop.gaming.enable {
    programs = {
      steam = {
        enable = true;

        # Translate X11 input events to uinput for Steam Input on Wayland (Niri)
        extest = {
          enable = true;
        };

        # Winetricks wrapper for Proton-enabled games
        protontricks = {
          enable = true;
        };

        remotePlay = {
          openFirewall = true;
        };

        localNetworkGameTransfers = {
          openFirewall = true;
        };

        # Proton-GE — community build with extra game fixes and media codecs
        extraCompatPackages = [
          pkgs.proton-ge-bin
        ];
      };

      # Gamescope — per-game Wayland compositor for resolution scaling,
      # frame limiting, and HDR. Used standalone (not as a full session via
      # gamescopeSession) so the Niri desktop stays the primary compositor.
      gamescope = {
        enable = true;

        # Allow Gamescope to renice itself for lower input latency
        capSysNice = true;
      };

      # Feral GameMode — on-demand performance optimizations when games launch
      gamemode = {
        enable = true;

        # Grant CAP_SYS_NICE so gamemoded can renice game processes
        enableRenice = true;

        settings = lib.mkMerge [
          {
            general = {
              # Renice game processes by -10 (lower = higher priority)
              renice = 10;
              # BEST_EFFORT I/O class, highest priority (0)
              ioprio = 0;
            };
          }
          # AMD GPU performance tuning — sets power_dpm_force_performance_level
          # to "high" via sysfs. Intel iGPUs lack this interface, so skip.
          (lib.mkIf isAmd {
            gpu = {
              apply_gpu_optimisations = "accept-responsibility";
              gpu_device = 0;
              amd_performance_level = "high";
            };
          })
        ];
      };
    };

    hardware = {
      # udev rules for Steam Controller, HTC Vive, and other gaming peripherals
      steam-hardware = {
        enable = true;
      };

      graphics = {
        # 32-bit Mesa, Vulkan loaders, and VA-API drivers for Proton/Wine.
        # programs.steam sets this internally, but keeping it explicit ensures
        # the 32-bit driver stack survives if Steam is ever factored out.
        enable32Bit = true;
      };
    };

    # MangoHud — Vulkan overlay for FPS/GPU/CPU stats (works with Steam,
    # native games, and Gamescope). ProtonUp-Qt — GUI for installing
    # additional Proton-GE versions into Steam's compatibilitytools.d,
    # complementing the declarative proton-ge-bin in extraCompatPackages.
    environment = {
      systemPackages = with pkgs; [
        mangohud
        protonup-qt
      ];
    };
  };
}
