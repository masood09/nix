# System packages and shell programs — base tools available on all NixOS machines.
# Shell selection (fish/zsh) and editor (neovim/vim) are driven by homelab options.
{
  config,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  neovimEnabled = homelabCfg.programs.neovim.enable or false;
in {
  environment = {
    systemPackages = with pkgs; [
      efibootmgr
      git
      kitty.terminfo
    ];
  };

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

    # Vim is always available as fallback; only set as default editor if neovim is off
    vim = {
      enable = true;
      defaultEditor = !neovimEnabled;
    };

    zsh = {
      inherit (homelabCfg.programs.zsh) enable;
    };
  };
}
