# Automatic Nix garbage collection.
#
# Schedules the equivalent of `sudo nix-collect-garbage --delete-older-than 14d`
# every Sunday at 06:00 on all NixOS machines. This complements the manual
# `just gc` recipe (default retention 7d) — the automatic version uses a longer
# 14d window so a single missed rollback is still recoverable after a weekend.
#
# Shared by every NixOS host (servers + desktops) via the imports list in
# `modules/nixos/default.nix`; there is no per-machine opt-out. See the
# sibling `_auto-update.nix` for the same OnCalendar pattern.
{
  nix = {
    gc = {
      # Install the nix-gc.service + nix-gc.timer systemd units.
      automatic = true;

      # systemd OnCalendar expression — same syntax as _auto-update.nix.
      # Sunday 06:00 local time (America/Toronto, set in modules/nixos/default.nix).
      dates = "Sun *-*-* 06:00:00";

      # Matches the user's intent: drop system profile generations older
      # than 14 days. Since home-manager stores its generations under
      # /nix/var/nix/profiles/per-user/<user>/, the root nix-gc also prunes
      # desktop users' HM history — no separate user timer is needed.
      options = "--delete-older-than 14d";

      # Stagger across machines so a homelab-wide wake-up doesn't hammer
      # every /nix store simultaneously. Mirrors _auto-update.nix.
      randomizedDelaySec = "10m";

      # Critical for the three NixOS laptops (arrakis, commandmodule, sonic)
      # which are typically asleep or powered off at 06:00 Sunday: systemd
      # records the last run in /var/lib/systemd/timers and fires the unit
      # shortly after the next boot if the scheduled slot was missed.
      persistent = true;
    };
  };
}
