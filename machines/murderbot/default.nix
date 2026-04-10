# murderbot — primary macOS dev machine (personal).
{
  imports = [
    ./hardware-configuration.nix

    ./../../modules/macos/base.nix
    ./../../modules/home-manager

    ./_dock.nix
    ./_packages.nix
  ];

  homelab = {
    role = "desktop";

    networking = {
      hostName = "murderbot";
    };

    programs = {
      fastfetch = {};
      # Central AI registry: install AI tool CLIs locally. No `models` list
      # because the only consumer (Noctalia's model-usage widget) is Linux-only,
      # so on Darwin it would be dead config.
      ai_tools = {
        enable = true;
        tools = [
          "claude-code"
          "codex"
          "opencode"
        ];
      };
      # element-desktop disabled on Darwin — provided by the Homebrew `element`
      # cask in ./_packages.nix as a temporary workaround. See that file for the
      # tech-debt note (nixpkgs build is broken on Darwin). Re-enable here once
      # the cask is dropped.
      # element-desktop = {
      #   enable = true;
      # };
      emacs = {
        enable = true;
      };
      fish = {
        enable = true;
      };
      git = {
        enable = true;
      };
      kitty = {
        enable = true;
      };
      neovim = {
        enable = true;
      };
      oci-cli = {
        enable = true;
      };
      opentofu = {
        enable = true;
      };
      zen = {
        enable = true;
      };
    };
  };
}
