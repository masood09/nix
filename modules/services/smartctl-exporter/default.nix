# smartctl exporter — surfaces per-disk SMART health (reallocated/pending
# sectors, drive temperature, power-on hours, SSD wear) so a failing drive is
# caught early rather than at the point of failure. Enable only on physical
# hosts; virtual disks (QEMU) expose no real SMART data. Auto-discovers all
# disks (the upstream `devices = []` default) and runs as the dedicated
# smartctl-exporter user with the raw-device access the upstream module grants.
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.services.smartctl-exporter;
in {
  imports = [
    ./alloy.nix
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    # The upstream module already grants the exporter the `disk` group,
    # CAP_SYS_RAWIO/ADMIN, and char-nvme device access — enough for SATA disks
    # (block devices are root:disk). But NVMe SMART is read from the controller
    # *char* device (/dev/nvme0), which ships root:root 0600, so the exporter
    # gets "Permission denied". Put NVMe controllers in the disk group the
    # exporter is already a member of.
    services = {
      udev = {
        extraRules = ''
          KERNEL=="nvme[0-9]*", SUBSYSTEM=="nvme", GROUP="disk", MODE="0660"
        '';
      };

      prometheus = {
        exporters = {
          smartctl = {
            enable = true;
            listenAddress = "127.0.0.1";
          };
        };
      };
    };
  };
}
