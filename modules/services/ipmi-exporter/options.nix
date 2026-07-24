# Options — Prometheus IPMI exporter (BMC hardware sensors).
{lib, ...}: {
  options = {
    homelab = {
      services = {
        ipmi-exporter = {
          enable = lib.mkEnableOption "the Prometheus IPMI exporter for local BMC sensors. Only hosts with a physical BMC exposing an in-band /dev/ipmi* interface.";
        };
      };
    };
  };
}
