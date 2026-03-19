# Desktop hardware — audio, GPU, bluetooth, and fingerprint reader.
# Only active on machines with role == "desktop". Bluetooth and fingerprint
# are individually gated behind their own enable flags.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  isDesktop = homelabCfg.role == "desktop";
in {
  options = {
    homelab = {
      hardware = {
        bluetooth = {
          enable = lib.mkEnableOption "bluetooth support";
        };

        fingerprint = {
          enable = lib.mkEnableOption "fingerprint reader support (fprintd)";
        };
      };
    };
  };

  config = lib.mkIf isDesktop {
    hardware = {
      bluetooth = lib.mkIf homelabCfg.hardware.bluetooth.enable {
        enable = true;
        powerOnBoot = true;
      };

      # GPU acceleration (mesa)
      graphics = {
        enable = true;
      };
    };

    security = {
      # RealtimeKit gives PipeWire realtime scheduling priority
      rtkit = {
        enable = true;
      };
    };

    services = {
      # PipeWire replaces PulseAudio + ALSA with a single unified daemon
      pipewire = {
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
      fprintd = {
        inherit (homelabCfg.hardware.fingerprint) enable;
      };
    };
  };
}
