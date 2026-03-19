# Neovim — opt-in editor with vi/vim aliases.
{homelabCfg, ...}: {
  programs = {
    neovim = {
      inherit (homelabCfg.programs.neovim) enable;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };
}
