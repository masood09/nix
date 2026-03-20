# Desktop hardware — audio, GPU, bluetooth, and fingerprint reader.
# Each feature is individually gated behind its own enable flag.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
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
      graphics = lib.mkIf homelabCfg.hardware.graphics.enable {
        enable = true;
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
