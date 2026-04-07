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
    ./_element-desktop.nix
    ./_eza.nix
    ./_fastfetch.nix
    ./_fd.nix
    ./_fzf.nix
    ./_ripgrep.nix
    ./_zoxide.nix

    # Development
    # Shared MCP registry imported before assistant modules that consume it.
    ./_mcp.nix
    ./_claude-code.nix
    ./_codex-cli.nix
    ./_emacs.nix
    ./_git.nix
    ./_gpg.nix
    ./_neovim.nix
    # Assistant module consuming the shared MCP registry from `_mcp.nix`.
    ./_opencode.nix

    # Cloud & infrastructure
    ./_oci-cli.nix
    ./_opentofu.nix

    # Desktop (Linux only, gated on niri.enable)
    ./niri

    # Applications
    ./zen

    # Per-role package lists
    ./_packages.nix
  ];
}
