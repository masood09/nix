# Disko disk layout — mirrored root pool + data pool.
{
  imports = [
    ./rootDisks.nix
    ./dataDisks.nix
  ];
}
