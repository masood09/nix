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
      # Not the kitty package: this is kitty's separate `terminfo` output — a
      # 20 KB path holding one file (share/terminfo/x/xterm-kitty) with zero
      # runtime references, substituted on its own from cache.nixos.org
      # (aarch64 included). It pulls no desktop closure onto headless servers.
      # Kept because ncurses ships `kitty`/`kitty-direct` but NOT `xterm-kitty`,
      # and its `kitty` entry is not an equivalent alias — kmous, blink, bw, km,
      # sgr and several kf* keys differ, so re-aliasing it would misdescribe the
      # terminal for anyone SSHing in from kitty.
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
