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
  options.homelab = {
    hardware.bluetooth.enable = lib.mkEnableOption "bluetooth support";
    hardware.fingerprint.enable = lib.mkEnableOption "fingerprint reader support (fprintd)";
  };

  config = lib.mkIf isDesktop {
    hardware = {
      bluetooth = lib.mkIf homelabCfg.hardware.bluetooth.enable {
        enable = true;
        powerOnBoot = true;
      };

      # GPU acceleration (mesa)
      graphics.enable = true;
    };

    # RealtimeKit gives PipeWire realtime scheduling priority
    security.rtkit.enable = true;

    # PipeWire replaces PulseAudio + ALSA with a single unified daemon
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    services.fprintd.enable = homelabCfg.hardware.fingerprint.enable;
  };
}
