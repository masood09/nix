# Fastfetch — system info display (neofetch successor).
# When showOnLogin is enabled, runs fastfetch on interactive shell login.
# Configures the default modules plus custom ones for role, reboot status,
# and ZFS pool health (if applicable).
{
  homelabCfg,
  lib,
  ...
}: let
  cfg = homelabCfg.programs.fastfetch;
  zshEnabled = homelabCfg.programs.zsh.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;

  # Custom command modules — role and reboot are prepended after the title,
  # desktop-only and zpool modules are appended after the common defaults.
  # The reboot guard uses `or false` because rebootRequiredCheck is a
  # NixOS-only option absent on macOS.

  roleModule = lib.optional (homelabCfg.purpose != "") {
    type = "command";
    key = "Role";
    text = "echo '${homelabCfg.purpose}'";
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

      settings = lib.mkIf cfg.enable ({
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
        }
        # TODO: kitty-direct requires a Kitty-compatible terminal. If machines
        # are accessed from non-Kitty terminals (plain SSH, tmux without
        # passthrough), the logo will render as garbage or fail silently.
        # Revisit: either let fastfetch auto-detect by dropping `type`, or
        # expose `logoType` as a configurable option with kitty-direct default.
        // lib.optionalAttrs (cfg.logo != null) {
          logo = {
            source = toString cfg.logo;
            type = "kitty-direct";
          };
        });
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
