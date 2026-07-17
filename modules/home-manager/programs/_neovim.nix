# Neovim — opt-in editor with vi/vim aliases.
{homelabCfg, ...}: {
  programs = {
    neovim = {
      inherit (homelabCfg.programs.neovim) enable;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # Adopt the nixos-26.05 defaults explicitly (they flip to false once
      # home.stateVersion >= 26.05). We don't use the Ruby or Python3 host
      # providers, so drop them to trim the closure and silence the warnings.
      withRuby = false;
      withPython3 = false;
    };
  };
}
