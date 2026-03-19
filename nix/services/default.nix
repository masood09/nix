# Custom NixOS service modules for apps not yet in nixpkgs.
{
  imports = [
    ./mailarchiver.nix
    ./matrix-authentication-service.nix
    ./nightscout.nix
  ];
}
