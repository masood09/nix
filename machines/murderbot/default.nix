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
      claude-code = {
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
