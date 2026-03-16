{lib, ...}: {
  options.homelab.services.dell-idrac-fan-controller = {
    enable = lib.mkEnableOption "Whether to enable Dell iDRAC Fan Controller.";

    idracHost = lib.mkOption {
      type = lib.types.str;
      default = "dell-r730xd-idrac-host.mgmt.homelab.mantannest.com";
      description = "Hostname or IP of the Dell iDRAC management interface.";
    };

    fanSpeed = lib.mkOption {
      type = lib.types.ints.between 0 100;
      default = 20;
      description = "Static fan speed percentage when CPU temperature is below threshold.";
    };

    cpuTemperatureThreshold = lib.mkOption {
      type = lib.types.int;
      default = 65;
      description = "CPU temperature (°C) above which Dell default fan control takes over.";
    };

    checkInterval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
      description = "Interval in seconds between temperature checks.";
    };

    disableThirdPartyPcieCardDellDefaultCoolingResponse = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to disable Dell's aggressive cooling for third-party PCIe cards.";
    };

    keepThirdPartyPcieCardCoolingResponseStateOnExit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to keep the third-party PCIe card cooling state when the controller exits.";
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Additional environment variables passed to the fan controller container.";
    };
  };
}
