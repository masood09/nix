# ixian — AMD desktop hardware for AI inference and a Steam Gaming Mode
# console, built from nixos-unstable for Jovian.
{inputs, ...}: {
  imports = [
    # Jovian's module installs a package overlay, so it is imported here
    # rather than in sharedNixOSModules to keep it off every other host.
    inputs.jovian.nixosModules.default

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
