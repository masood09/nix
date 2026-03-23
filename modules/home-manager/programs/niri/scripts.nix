# Niri helper scripts — run-or-raise scripts managed as Nix derivations
{pkgs}: {
  run-or-raise-zen = pkgs.writeShellScript "run-or-raise-zen" ''
    # Run-or-raise script for Zen browser
    # If Zen is running, focus it. Otherwise, launch it.

    if ${pkgs.niri}/bin/niri msg windows | ${pkgs.gnugrep}/bin/grep -q 'App ID: "zen-beta"'; then
      # Zen is running, focus it
      # Get the window ID of zen (extract number after "Window ID ")
      window_id=$(${pkgs.niri}/bin/niri msg windows | ${pkgs.gnugrep}/bin/grep -B2 'App ID: "zen-beta"' | ${pkgs.gnugrep}/bin/grep "Window ID" | ${pkgs.coreutils}/bin/head -1 | ${pkgs.gnused}/bin/sed 's/Window ID \([0-9]*\):.*/\1/')
      if [ -n "$window_id" ]; then
        ${pkgs.niri}/bin/niri msg action focus-window --id "$window_id"
      fi
    else
      # Zen is not running, launch it
      zen-beta &
    fi
  '';

  run-or-raise-emacs = pkgs.writeShellScript "run-or-raise-emacs" ''
    # Run-or-raise script for Emacs
    # If Emacs is running, focus it. Otherwise, launch it.

    # Check for emacs window (app-id is "emacs")
    if ${pkgs.niri}/bin/niri msg windows | ${pkgs.gnugrep}/bin/grep -qi 'App ID: "emacs"'; then
      # Emacs is running, focus it
      # Get the window ID of emacs (extract number after "Window ID ")
      window_id=$(${pkgs.niri}/bin/niri msg windows | ${pkgs.gnugrep}/bin/grep -B 2 -i 'App ID: "emacs"' | ${pkgs.gnugrep}/bin/grep "Window ID" | ${pkgs.coreutils}/bin/head -1 | ${pkgs.gnused}/bin/sed 's/Window ID \([0-9]*\):.*/\1/')
      if [ -n "$window_id" ]; then
        ${pkgs.niri}/bin/niri msg action focus-window --id "$window_id"
      fi
    else
      # Emacs is not running, launch it
      emacs &
    fi
  '';
}
