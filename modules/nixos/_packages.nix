{
  config,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  neovimEnabled = homelabCfg.programs.neovim.enable or false;
in {
  environment.systemPackages = with pkgs; [
    efibootmgr
    ghostty.terminfo
    git
    gptfdisk
    parted
  ];

  programs = {
    fish = {
      inherit (homelabCfg.programs.fish) enable;
    };

    neovim = {
      inherit (homelabCfg.programs.neovim) enable;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    vim = {
      enable = true;
      defaultEditor = !neovimEnabled;
    };

    zsh = {
      inherit (homelabCfg.programs.zsh) enable;
    };
  };
}
