# murderbot — primary macOS dev machine (personal).
{
  imports = [
    ./hardware-configuration.nix

    ./../../modules/macos/base.nix
    ./../../modules/home-manager

    ./_dock.nix
    ./_packages.nix
  ];

  nixpkgs = {
    overlays = [
      (import ../../nix/overlays/darwin-setproctitle.nix)
    ];
  };

  homelab = {
    role = "desktop";

    networking = {
      hostName = "murderbot";
    };

    programs = {
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
      zen = {
        enable = true;
      };
    };
  };
}
