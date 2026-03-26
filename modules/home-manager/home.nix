# Home environment — base home-manager config shared across all machines.
# Sets up home directory path (Linux vs macOS) and imports all program modules.
{
  lib,
  pkgs,
  homelabCfg,
  inputs,
  ...
}: {
  # Servers have no D-Bus session, so dconf writes (e.g. Stylix GTK/cursor
  # themes) fail with "ca.desrt.dconf was not provided by any .service files".
  dconf = {
    enable = lib.mkDefault (homelabCfg.role == "desktop");
  };
  imports = [
    ./programs
    # Zen browser home-manager module (beta variant)
    inputs.zen-browser.homeModules.beta
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

  # Nicely reload system units when changing configs
  # Self-note: nix-darwin seems to luckily ignore this setting
  systemd = {
    user = {
      startServices = "sd-switch";
    };
  };
}
