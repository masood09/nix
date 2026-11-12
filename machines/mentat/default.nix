# mentat — secondary DNS (Blocky) and, in a later phase, the Hermes agent.
# Bare-metal Intel N100 mini PC with a single NVMe: encrypted single-disk
# ZFS root with impermanence.
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
      root = [
        "nvme-WDC_PC_SN730_SDBQNTY-256G-1001_194364802297"
      ];
    };
  };
}
