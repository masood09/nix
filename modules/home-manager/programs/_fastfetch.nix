# Fastfetch — system info display (neofetch successor).
# Uses fastfetch's built-in logo auto-detection (run `fastfetch --list-logos`
# to see available logos). When showOnLogin is enabled, runs fastfetch on
# interactive shell login. Configures the default modules plus custom ones
# for role, reboot status, and ZFS pool health (if applicable).
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.fastfetch;
  isServer = (homelabCfg.role or "") == "server";

  # nixpkgs' default fastfetch enables every backend, dragging the whole
  # desktop graphics stack (wayland, X11, vulkan, opengl, opencl, imagemagick +
  # chafa, libpulseaudio, ddcutil, xfconf, dconf) into the closure — ~150 MiB
  # of libraries for modules a headless server never renders. On servers we
  # only show text modules (os/host/cpu/mem/disk/zpool), so strip the GUI
  # backends. Desktops keep the full-featured build.
  serverPackage = pkgs.fastfetch.override {
    x11Support = false;
    waylandSupport = false;
    vulkanSupport = false;
    openglSupport = false;
    openclSupport = false;
    imageSupport = false;
    audioSupport = false;
    brightnessSupport = false;
    xfceSupport = false;
    gnomeSupport = false;
    dbusSupport = false;
  };
  zshEnabled = homelabCfg.programs.zsh.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;

  # Custom command modules — role and reboot are prepended after the title,
  # desktop-only and zpool modules are appended after the common defaults.
  # Several options below use `or` fallbacks (purpose, rebootRequiredCheck,
  # role) because they are NixOS-only and absent on macOS.

  roleModule = lib.optional ((homelabCfg.purpose or "") != "") {
    type = "command";
    key = "Role";
    text = "echo '${homelabCfg.purpose or ""}'";
  };

  rebootModule = lib.optionals (homelabCfg.services.rebootRequiredCheck.enable or false) [
    {
      type = "command";
      key = "Reboot";
      text = "if [ -f /var/run/reboot-required ]; then echo 'Required'; else echo 'Not required'; fi";
    }
  ];

  isDesktop = (homelabCfg.role or "") == "desktop";

  # Modules only relevant on desktop machines
  desktopModules = lib.optionals isDesktop [
    "packages"
    "display"
    "de"
    "wm"
    "wmtheme"
    "theme"
    "icons"
    "font"
    "cursor"
    "gpu"
    "battery"
    "poweradapter"
  ];

  zpoolModules = lib.optionals (cfg.zpools != []) (
    [
      "separator"
      {
        type = "command";
        key = "ZPool Status";
        text = "zpool status -x 2>/dev/null || echo 'N/A'";
      }
    ]
    ++ lib.forEach cfg.zpools (pool: {
      type = "command";
      key = "ZPool (${pool})";
      text = "echo \"$(zpool list -Ho cap ${pool} 2>/dev/null) used\" || echo 'N/A'";
    })
  );
in {
  programs = {
    fastfetch = {
      inherit (cfg) enable;

      package = lib.mkIf isServer serverPackage;

      settings = lib.mkIf cfg.enable {
        # Module order: title → custom (role, reboot) → defaults → ZFS → colors
        modules =
          [
            "title"
            "separator"
          ]
          ++ roleModule
          ++ rebootModule
          ++ [
            "os"
            "host"
            "kernel"
            "uptime"
            "shell"
            "terminal"
            "terminalfont"
            "cpu"
            "memory"
            "swap"
            "disk"
            "localip"
            "locale"
          ]
          ++ desktopModules
          ++ zpoolModules
          ++ [
            "break"
            "colors"
          ];
      };
    };

    # Shell integration — show fastfetch on interactive login
    zsh = {
      initContent = lib.mkIf (cfg.enable && cfg.showOnLogin && zshEnabled) (lib.mkOrder cfg.zshInitOrder ''
        [[ -o interactive ]] && command -v fastfetch >/dev/null 2>&1 && fastfetch
      '');
    };

    fish = {
      interactiveShellInit = lib.mkIf (cfg.enable && cfg.showOnLogin && fishEnabled) (lib.mkAfter ''
        if status is-interactive
          command -sq fastfetch; and fastfetch
        end
      '');
    };
  };
}
