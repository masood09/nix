# Hardware config — Apple Silicon Mac (aarch64-darwin).
{lib, ...}: {
  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-darwin";
  };
}
