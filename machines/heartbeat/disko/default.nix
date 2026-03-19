# Disko disk layout — mirrored root pool + data pool (HDD) + fast pool (SSD).
{
  imports = [
    ./rootDisks.nix
    ./dataDisks.nix
    ./fastDisks.nix
  ];
}
