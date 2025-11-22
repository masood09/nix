{
  lib,
  pkgs,
  homelabCfg,
  ...
}: let
  defaultEditor =
    if homelabCfg.programs.neovim.enable
    then "nvim"
    else "vim";
in {
  imports = [
    ./programs
  ];

  home = {
    username = homelabCfg.primaryUser.userName;

    homeDirectory = lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isLinux "/home/${homelabCfg.primaryUser.userName}")
      (lib.mkIf pkgs.stdenv.isDarwin "/Users/${homelabCfg.primaryUser.userName}")
    ];

    stateVersion = "25.05";

    sessionVariables =
      {
        EDITOR = defaultEditor;
        VISUAL = defaultEditor;
      }
      // lib.mkIf pkgs.stdenv.isDarwin {
        SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
      };
  };

  # Nicely reload system units when changing configs
  # Self-note: nix-darwin seems to luckily ignore this setting
  systemd.user.startServices = "sd-switch";
}
