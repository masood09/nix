{
  lib,
  pkgs,
  inputs,
  homelabCfg,
  ...
}: {
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.nvf.homeManagerModules.default

    ./_packages.nix
    ./fish.nix
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
        EDITOR = "vim";
        VISUAL = "vim";
      }
      // lib.mkIf pkgs.stdenv.isDarwin {
        SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
      };
  };

  programs = {
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    bat.enable = true;
    btop.enable = true;
    eza.enable = true;
    fastfetch.enable = true;
    htop.enable = true;
    nh.enable = true;
  };

  catppuccin = {
    enable = true;
  };

  # Nicely reload system units when changing configs
  # Self-note: nix-darwin seems to luckily ignore this setting
  systemd.user.startServices = "sd-switch";
}
