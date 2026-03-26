# Desktop modules — shared desktop services, hardware, and compositor(s).
# desktop.enable gates shared services (accounts-daemon, printing, fonts, etc.).
# Hardware features and compositors are individually gated behind their own enable flags.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  gfxCfg = homelabCfg.hardware.graphics;
  isIntel = gfxCfg.driver == "intel";
  isAmd = gfxCfg.driver == "amd";
in {
  imports = [
    ./_greetd.nix
    ./_niri.nix
  ];

  options = {
    homelab = {
      desktop = {
        enable = lib.mkEnableOption "desktop environment (shared services, login manager)";
      };

      hardware = {
        audio = {
          enable = lib.mkEnableOption "audio support";
        };

        bluetooth = {
          enable = lib.mkEnableOption "bluetooth support";
        };

        fingerprint = {
          enable = lib.mkEnableOption "fingerprint reader support (fprintd)";
        };

        graphics = {
          enable = lib.mkEnableOption "graphics support";

          driver = lib.mkOption {
            default = "intel";
            type = lib.types.enum [
              "intel"
              "amd"
            ];
            description = "GPU driver family — determines which VA-API/VDPAU packages to install.";
          };
        };
      };
    };
  };

  config = {
    hardware = {
      bluetooth = lib.mkIf homelabCfg.hardware.bluetooth.enable {
        enable = true;
        powerOnBoot = true;
      };

      # GPU acceleration (mesa)
      graphics = lib.mkIf gfxCfg.enable {
        enable = true;

        extraPackages = with pkgs;
          if isIntel
          then [
            intel-media-driver # iHD — hardware video decode/encode (Broadwell+)
            intel-vaapi-driver # i965 — fallback for older Intel iGPUs
            intel-compute-runtime # OpenCL runtime (NEO)
            libva-vdpau-driver # VDPAU compatibility layer over VA-API
            libvdpau-va-gl # VDPAU fallback via OpenGL
          ]
          else [
            # AMD uses mesa's built-in RADV/radeonsi — no extra VA-API driver needed
            rocmPackages.clr # OpenCL runtime (ROCm)
            libvdpau-va-gl # VDPAU fallback via OpenGL
          ];
      };

      # AMD GPU kernel driver
      amdgpu = lib.mkIf (gfxCfg.enable && isAmd) {
        initrd = {
          enable = true;
        };
      };
    };

    security = {
      # RealtimeKit gives PipeWire realtime scheduling priority
      rtkit = lib.mkIf homelabCfg.hardware.audio.enable {
        enable = true;
      };
    };

    services = {
      # PipeWire replaces PulseAudio + ALSA with a single unified daemon
      pipewire = lib.mkIf homelabCfg.hardware.audio.enable {
        enable = true;

        alsa = {
          enable = true;
          # 32-bit compatibility for Wine/Steam
          support32Bit = true;
        };

        pulse = {
          enable = true;
        };
      };

      # Fingerprint authentication daemon
      fprintd = lib.mkIf homelabCfg.hardware.fingerprint.enable {
        enable = true;
      };

      # Shared desktop service dependencies (compositor-agnostic)
      accounts-daemon = lib.mkIf homelabCfg.desktop.enable {
        enable = true;
      };

      power-profiles-daemon = lib.mkIf homelabCfg.desktop.enable {
        enable = true;
      };

      printing = lib.mkIf homelabCfg.desktop.enable {
        enable = true;
      };

      # Battery/power monitoring
      upower = lib.mkIf homelabCfg.desktop.enable {
        enable = true;
      };
    };

    # Wayland session — toolkit hints and VA-API driver selection
    environment = {
      sessionVariables = lib.mkMerge [
        (lib.mkIf homelabCfg.desktop.enable {
          NIXOS_OZONE_WL = "1"; # Electron apps: use native Wayland
          MOZ_ENABLE_WAYLAND = "1"; # Firefox/Zen: use native Wayland
        })
        (lib.mkIf gfxCfg.enable {
          # iHD = Broadwell+ Intel (UHD 620, etc.), radeonsi = AMD (RDNA, etc.)
          LIBVA_DRIVER_NAME =
            if isIntel
            then "iHD"
            else "radeonsi";
        })
      ];
    };

    fonts = lib.mkIf homelabCfg.desktop.enable {
      fontconfig = {
        # Required for user-installed fonts to be discovered
        enable = true;
      };

      packages = with pkgs; [
        # Sans-serif / serif
        dejavu_fonts
        noto-fonts
        noto-fonts-cjk-sans
        # Emoji
        noto-fonts-color-emoji
      ];
    };
  };
}
