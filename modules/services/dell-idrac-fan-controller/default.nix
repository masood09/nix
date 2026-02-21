{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.dell-idrac-fan-controller;
  podmanEnabled = homelabCfg.services.podman.enable;

  boolStr = b:
    if b
    then "true"
    else "false";

  ipmiCpuTempProbe = pkgs.writeShellScript "ipmi-cpu-temp-probe" ''
    set -euo pipefail

    out="$(${pkgs.ipmitool}/bin/ipmitool \
      -I lanplus \
      -H ${cfg.idracHost} \
      -U "$IDRAC_USERNAME" \
      -P "$IDRAC_PASSWORD" \
      sdr type temperature 2>/dev/null || true)"

    # Require at least one CPU temp reading (entity 3.x + degrees C)
    if ! printf "%s\n" "$out" | ${pkgs.gawk}/bin/awk '
      $0 ~ /degrees C/ && $0 ~ /\|[[:space:]]*3\.[0-9]+[[:space:]]*\|/ { ok=1 }
      END { exit ok?0:1 }
    '; then
      echo "No CPU temperature readings available (host likely off). Skipping fan controller."
      exit 1
    fi
  '';
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
        config.sops.secrets."dell-idrac-fan-controller/.env".path
      ];
    };

    systemd.services.podman-dell-idrac-fan-controller.serviceConfig = {
      EnvironmentFile = config.sops.secrets."dell-idrac-fan-controller/.env".path;
      ExecCondition = ipmiCpuTempProbe;
    };
  };
}
