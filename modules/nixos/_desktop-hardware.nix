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

      graphics.enable = true;
    };

    security.rtkit.enable = true;

    # Audio (PipeWire)
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Fingerprint reader
    services.fprintd.enable = homelabCfg.hardware.fingerprint.enable;

  };
}
