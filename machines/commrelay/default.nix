# commrelay — federated messaging server (Matrix Synapse).
{
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_secrets.nix

    ./../../modules/nixos
    ./../../modules/home-manager

    ./_caddy.nix
  ];

  homelab = {
    disks = {
      root = [
        "scsi-3600eccee132b4016afad1991ab86365f"
      ];
    };
  };
}
