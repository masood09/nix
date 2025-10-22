{vars, ...}: {
  imports = [
    ./../../modules/nixos/iso.nix
  ];

  networking.hostName = "nixiso";
}
