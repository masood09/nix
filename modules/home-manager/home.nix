# Home environment — base home-manager config shared across all machines.
# Sets up home directory path (Linux vs macOS), XDG directories, fontconfig
# overrides, and imports all program modules.
# Stylix HM module is auto-imported by the NixOS/Darwin system module
# (autoImport + followSystem); no explicit import is needed here.
{
  config,
  lib,
  pkgs,
  homelabCfg,
  inputs,
  ...
}: let
  # Servers don't enable homelab.stylix so the Stylix HM module is never
  # auto-imported — config.stylix won't exist.  Use `or false` to fall back
  # gracefully.  monoFont is only forced when stylixEnabled is true (lazy).
  stylixEnabled = config.stylix.enable or false;
  monoFont = config.stylix.fonts.monospace.name;
in {
  # Servers have no D-Bus session, so dconf writes (e.g. Stylix GTK/cursor
  # themes) fail with "ca.desrt.dconf was not provided by any .service files".
  dconf = {
    enable = lib.mkDefault (homelabCfg.role == "desktop");
  };
  imports = [
    ./programs
    # Zen browser home-manager module (beta variant)
    inputs.zen-browser.homeModules.beta
    # Noctalia desktop shell home-manager module
    inputs.noctalia.homeModules.default
  ];

  home = {
    username = homelabCfg.primaryUser.userName;

    # Home directory differs between Linux (/home/) and macOS (/Users/)
    homeDirectory = lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isLinux "/home/${homelabCfg.primaryUser.userName}")
      (lib.mkIf pkgs.stdenv.isDarwin "/Users/${homelabCfg.primaryUser.userName}")
    ];

    stateVersion = "25.11";

    # macOS needs explicit SOPS key path (NixOS machines use the system age key)
    sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
    };
  };

  # Fontconfig — redirect common monospace fonts (Liberation Mono, DejaVu Sans
  # Mono, Noto Sans Mono) to the Stylix monospace font so web pages and apps
  # requesting these fonts get Nerd Font PUA icon glyphs.
  #
  # XDG user directories (Desktop, Documents, Downloads, etc.) are created on
  # Linux desktops only — skipped on macOS (xdg-user-dirs is freedesktop-only)
  # and servers (no interactive desktop session).
  xdg = {
    configFile = lib.mkIf stylixEnabled {
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

    userDirs = {
      enable = pkgs.stdenv.isLinux && homelabCfg.role == "desktop";
      createDirectories = true;
    };
  };

  # Nicely reload system units when changing configs
  # Self-note: nix-darwin seems to luckily ignore this setting
  systemd = {
    user = {
      startServices = "sd-switch";
    };
  };
}
