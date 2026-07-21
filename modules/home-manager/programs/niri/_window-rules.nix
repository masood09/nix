# Niri window rules — the `programs.niri.settings.window-rules` list.
# Not a Home Manager module: a plain list imported by ./default.nix.
# Shared across both laptops, including the Steam/Proton gaming rules, because
# they apply consistently regardless of machine.
_: [
  {
    # Empty default-column-width lets wezterm use its own requested size
    # rather than the global 50% proportion default.
    matches = [{app-id = "^org\\.wezfurlong\\.wezterm$";}];
    default-column-width = {};
  }
  {
    # Global rule (no `matches`): rounded corners on all tiled windows.
    geometry-corner-radius = {
      bottom-left = 12.0;
      bottom-right = 12.0;
      top-left = 12.0;
      top-right = 12.0;
    };
    clip-to-geometry = true;
    tiled-state = true;
    draw-border-with-background = false;
  }
  {
    matches = [
      {
        app-id = "firefox$";
        title = "^Picture-in-Picture$";
      }
      {
        app-id = "^zoom$";
      }
    ];
    open-floating = true;
  }
  {
    matches = [
      {
        app-id = "^org\\.gnome\\.Nautilus$";
      }
      {
        app-id = "^xdg-desktop-portal$";
      }
    ];
    open-floating = true;
  }
  {
    matches = [
      {
        app-id = "^org\\.keepassxc\\.KeePassXC$";
      }
      {
        app-id = "^org\\.gnome\\.World\\.Secrets$";
      }
    ];
    block-out-from = "screen-capture";
  }
  {
    # Steam client windows — float so the store/library UI doesn't
    # tile, but don't fullscreen (it's a regular desktop app).
    # Both casings appear depending on Steam/XWayland version.
    matches = [
      {app-id = "^steam$";}
      {app-id = "^Steam$";}
    ];
    open-floating = true;
  }
  {
    # Proton/Wine games and Gamescope — open fullscreen so XWayland
    # games fill the display and cursor coordinates map correctly.
    # steam_app_ is a prefix (no $ anchor) — Proton games report as
    # steam_app_<appid> (e.g. steam_app_813780 for AoE2:DE).
    matches = [
      {app-id = "^steam_app_";}
      {app-id = "^gamescope$";}
    ];
    open-fullscreen = true;
  }
]
