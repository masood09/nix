{
  system.autoUpgrade = {
    enable = true;
    dates = "Sat *-*-* 07:00:00";
    randomizedDelaySec = "1h";
    flake = "github:masood09/nix";
  };
}
