{ config, lib, ... }:
let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.dell-idrac-fan-controller;
  podmanEnabled = homelabCfg.services.podman.enable;

  boolStr = b: if b then "true" else "false";
in {
  options.homelab.services.dell-idrac-fan-controller = {
    enable = lib.mkEnableOption "Whether to enable Dell iDRAC Fan Controller.";

    idracHost = lib.mkOption {
      type = lib.types.str;
      default = "dell-r730xd-idrac-host.mgmt.homelab.mantannest.com";
    };

    fanSpeed = lib.mkOption {
      type = lib.types.ints.between 0 100;
      default = 20;
    };

    cpuTemperatureThreshold = lib.mkOption {
      type = lib.types.int;
      default = 65;
    };

    checkInterval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
    };

    disableThirdPartyPcieCardDellDefaultCoolingResponse = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    keepThirdPartyPcieCardCoolingResponseStateOnExit = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };
  };

  config = lib.mkIf (cfg.enable && podmanEnabled) {
    virtualisation.oci-containers.containers.dell-idrac-fan-controller = {
      # renovate: datasource=docker depName=tigerblue77/dell_idrac_fan_controller
      image = "tigerblue77/dell_idrac_fan_controller:v1.11";
      autoStart = true;

      environment =
        {
          IDRAC_HOST = cfg.idracHost;
          FAN_SPEED = toString cfg.fanSpeed;
          CPU_TEMPERATURE_THRESHOLD = toString cfg.cpuTemperatureThreshold;
          CHECK_INTERVAL = toString cfg.checkInterval;
          DISABLE_THIRD_PARTY_PCIE_CARD_DELL_DEFAULT_COOLING_RESPONSE =
            boolStr cfg.disableThirdPartyPcieCardDellDefaultCoolingResponse;
          KEEP_THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE_STATE_ON_EXIT =
            boolStr cfg.keepThirdPartyPcieCardCoolingResponseStateOnExit;
        }
        // cfg.extraEnvironment;

      environmentFiles = [
        config.sops.secrets."dell-idrac-fan-controller-env".path
      ];
    };
  };
}
