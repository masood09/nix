# Options — Prometheus smartctl exporter (disk SMART health).
{lib, ...}: {
  options = {
    homelab = {
      services = {
        smartctl-exporter = {
          enable = lib.mkEnableOption "the Prometheus smartctl exporter for per-disk SMART health. Physical hosts only — virtual disks expose no real SMART data.";
        };
      };
    };
  };
}
