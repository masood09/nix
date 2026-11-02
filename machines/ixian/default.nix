# ixian — AMD desktop hardware for headless-first AI inference and gaming.
# The desktop-capable flake builder is used now so this host can be promoted
# to a graphical desktop later without changing its machine wiring.
{
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_secrets.nix
    ./_users.nix

    ./../../modules/nixos
    ./../../modules/home-manager
  ];

  homelab = {
    disks = {
      root = [
        "nvme-CT1000P3PSSD8_24504CBE7C25"
      ];

      data = [
        "nvme-CT1000P3PSSD8_24504CBE7C73"
      ];
    };
  };
}
