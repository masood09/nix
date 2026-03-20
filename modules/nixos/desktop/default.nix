# Desktop modules — hardware (audio, GPU, bluetooth, fingerprint) and Niri compositor.
# Hardware features are individually gated behind their own enable flags.
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
            vaapiVdpau # VDPAU compatibility layer over VA-API
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
    };
  };
}
