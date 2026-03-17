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
    hardware.thermald.enable = lib.mkEnableOption "Intel thermald (disable for ThinkPads with DYTC)";
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

    # Power management
    services.thermald.enable = homelabCfg.hardware.thermald.enable;
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      };
    };
  };
}
