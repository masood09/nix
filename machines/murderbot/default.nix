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

    stylix = {
      enable = true;
    };

    networking = {
      hostName = "murderbot";
    };

    programs = {
      fastfetch = {};
      # Central AI registry: install opencode locally; the shared selector also
      # keeps Noctalia-compatible provider choices in one machine-facing place.
      ai_tools = {
        enable = true;
        models = ["codex"];
        tools = ["opencode"];
      };
      element-desktop = {
        enable = true;
      };
      emacs = {
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
