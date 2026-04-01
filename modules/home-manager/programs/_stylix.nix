# Home-Manager Stylix — Base16 theming for user-level programs (terminal, GTK,
# cursor, waybar, etc.).  System-level theming (Plymouth, GRUB, console) is
# handled by the NixOS-level module in modules/nixos/_stylix.nix.
{
  config,
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.stylix;
  monoFont = config.stylix.fonts.monospace.name;
in {
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  # Fontconfig — redirect NixOS default monospace fonts (Liberation Mono, DejaVu
  # Sans Mono, Noto Sans Mono) to the Stylix monospace font. Without this, web
  # pages and apps requesting these fonts would miss Nerd Font PUA icon glyphs.
  xdg = lib.mkIf cfg.enable {
    configFile = {
      "fontconfig/conf.d/60-nerd-font-override.conf" = {
        text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <!-- Replace monospace fonts that lack Nerd Font icons -->
            <match target="pattern">
              <test qual="any" name="family"><string>Liberation Mono</string></test>
              <edit name="family" mode="assign" binding="strong">
                <string>${monoFont}</string>
              </edit>
            </match>
            <match target="pattern">
              <test qual="any" name="family"><string>DejaVu Sans Mono</string></test>
              <edit name="family" mode="assign" binding="strong">
                <string>${monoFont}</string>
              </edit>
            </match>
            <match target="pattern">
              <test qual="any" name="family"><string>Noto Sans Mono</string></test>
              <edit name="family" mode="assign" binding="strong">
                <string>${monoFont}</string>
              </edit>
            </match>
          </fontconfig>
        '';
      };
    };
  };

  stylix = lib.mkIf cfg.enable {
    enable = true;

    # Base16 color scheme — path to a custom YAML file, or a named scheme
    # from the base16-schemes package (e.g. "catppuccin-mocha").
    base16Scheme =
      if builtins.isPath cfg.scheme
      then cfg.scheme
      else "${pkgs.base16-schemes}/share/themes/${cfg.scheme}.yaml";

    # Theme polarity (dark/light)
    inherit (cfg) polarity;

    # Wallpaper for color extraction (optional)
    image = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;

    # Fonts — families and sizes applied uniformly across terminal and GUI apps
    fonts = {
      sizes = {
        terminal = 12;
        applications = 12;
      };

      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.inter;
        name = "Inter";
      };
    };

    # Cursor theme
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # Opacity settings
    opacity = {
      terminal = 0.90;
      popups = 0.90;
    };

    targets = {
      # Disable Starship target - it uses hardcoded Catppuccin colors
      starship = {
        enable = false;
      };
      # Keep color variables and fonts, drop layout/padding/tooltip CSS
      waybar = {
        addCss = false;
      };
    };
  };
}
