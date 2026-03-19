# Auto-upgrade — pulls the latest flake from GitHub every Saturday morning.
# Each machine staggers its upgrade by up to 10 minutes to avoid thundering herd.
{
  system.autoUpgrade = {
    enable = true;
    dates = "Sat *-*-* 07:00:00";
    randomizedDelaySec = "10m";
    flake = "github:masood09/nix";
  };
}
