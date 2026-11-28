# guild — Lenovo ThinkCentre M920 (i5-8500, 64 GB): the fleet's future CI/CD
# and binary-cache server, and a host for a Hermes agent under its own user.
# Encrypted single-disk ZFS root (the server layout, as on mentat) plus two
# encrypted single-disk data pools, cipool and agentpool (disko/default.nix).
{
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_secrets.nix

    ./../../modules/nixos
    ./../../modules/home-manager
  ];

  homelab = {
    disks = {
      # Patriot P220 128 GB SATA: EFI + encrypted rpool (no swap).
      root = [
        "ata-Patriot_P220_128GB_P220HHBB241107006863"
      ];

      # ~20% of the ~118 GiB rpool partition, so it never fills past ~80%
      # (same rule as cipool/agentpool in disko/default.nix).
      rootReservation = "24G";

      # Crucial P3 1 TB NVMe: cipool (CI builds, binary cache).
      fast = [
        "nvme-CT1000P3PSSD8_25014D6B1BD7"
      ];

      # Patriot P220 1 TB SATA: agentpool (Hermes agent).
      data = [
        "ata-Patriot_P220_1024GB_P2204IBB25040902529"
      ];
    };
  };
}
