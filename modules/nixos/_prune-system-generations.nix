{
  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "Sat *-*-* 22:00:00";
        options = "--delete-older-than 30d";
      };

      settings = {
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;
      };
    };

    systemd.services.nix-prune-system-generations = {
      description = "Prune NixOS system profile generations (keep last 7)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +7";
      };
    };

    systemd.timers.nix-prune-system-generations = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "Sat *-*-* 21:50:00";
        Persistent = true;
      };
    };
  };
}
