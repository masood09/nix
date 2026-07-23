# IPMI exporter — reads the local BMC over the in-band interface (/dev/ipmi0)
# for chassis temperatures, fan RPM, PSU status, voltages, and the hardware
# system event log. Enable only on hosts with a physical BMC. On heartbeat this
# reads its own Supermicro BMC — distinct from dell-idrac-fan-controller, which
# reaches out over the network to a *separate* Dell R730xd's iDRAC to drive its
# fans and is not about this host's own sensors.
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.ipmi-exporter;
in {
  imports = [
    ./alloy.nix
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    # The upstream exporter runs hardened (DynamicUser, PrivateDevices=true),
    # which hides /dev/ipmi0 entirely, so freeipmi reports "could not find
    # inband device". Grant in-band BMC access: a udev rule puts the device in
    # a dedicated `ipmi` group (0660), the exporter joins that group, and
    # PrivateDevices is lifted so the real /dev is visible. No extra DeviceAllow
    # is needed — with PrivateDevices off and no allow-list, the device cgroup
    # policy stays permissive and file-mode group access is what gates it.
    users = {
      groups = {
        ipmi = {};
      };
    };

    services = {
      udev = {
        extraRules = ''
          SUBSYSTEM=="ipmi", KERNEL=="ipmi*", GROUP="ipmi", MODE="0660"
        '';
      };

      prometheus = {
        exporters = {
          ipmi = {
            enable = true;
            listenAddress = "127.0.0.1";
          };
        };
      };
    };

    systemd = {
      services = {
        prometheus-ipmi-exporter = {
          serviceConfig = {
            PrivateDevices = lib.mkForce false;
            SupplementaryGroups = ["ipmi"];
          };
        };
      };
    };
  };
}
