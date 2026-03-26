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

  # Custom command modules — prepended/appended to the default module list.
  # Guards use `or false` because these NixOS-only options are absent on macOS.

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

  zfsModules = lib.optionals (homelabCfg.isRootZFS or false) [
    "separator"
    {
      type = "command";
      key = "ZPool Status";
      text = "zpool status -x 2>/dev/null || echo 'N/A'";
    }
    {
      type = "command";
      key = "ZPool Usage";
      text = "zpool list -Ho name,cap,size 2>/dev/null | awk '{printf \"%s: %s used of %s\\n\", $1, $2, $3}' || echo 'N/A'";
    }
  ];
in {
  programs = {
    fastfetch = {
      inherit (cfg) enable;

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
            "packages"
            "shell"
            "display"
            "de"
            "wm"
            "wmtheme"
            "theme"
            "icons"
            "font"
            "cursor"
            "terminal"
            "terminalfont"
            "cpu"
            "gpu"
            "memory"
            "swap"
            "disk"
            "localip"
            "battery"
            "poweradapter"
            "locale"
          ]
          ++ zfsModules
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
