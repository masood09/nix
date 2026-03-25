# Program modules — each _<name>.nix configures one program/tool.
# All are imported unconditionally; each module guards itself internally
# with lib.mkIf based on its homelab.programs.<name>.enable flag.
{
  imports = [
    # Shell & terminal
    ./_bash.nix
    ./_fish.nix
    ./_zsh.nix
    ./_kitty.nix
    ./_tmux.nix
    ./_starship.nix

    # CLI tools
    ./_bat.nix
    ./_btop.nix
    ./_direnv.nix
    ./_eza.nix
    ./_fastfetch.nix
    ./_fd.nix
    ./_fzf.nix
    ./_ripgrep.nix
    ./_zoxide.nix

    # Development
    ./_claude-code.nix
    ./_emacs.nix
    ./_git.nix
    ./_gpg.nix
    ./_neovim.nix

    # Cloud & infrastructure
    ./_oci-cli.nix
    ./_opentofu.nix

    # Desktop (Linux only, gated on niri.enable)
    ./niri
    ./_dms.nix

    # Applications
    ./zen

    # Theming & UX
    ./_stylix.nix
    ./_motd.nix

    # Per-role package lists
    ./_packages.nix
  ];
}
