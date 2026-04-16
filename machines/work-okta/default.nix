# work-okta — Okta work macOS machine. Minimal Zen profile (work-minimal),
# no git signing, work-only SSH keys. Corporate Artifactory proxy blocks
# third-party Homebrew taps (see _packages.nix).
{
  imports = [
    ./hardware-configuration.nix

    ./../../modules/macos/base.nix
    ./../../modules/home-manager

    ./_dock.nix
    ./_packages.nix
    ./_zen.nix
  ];

  # Show menu bar — no sketchybar on this machine (blocked by Artifactory)
  system = {
    defaults = {
      NSGlobalDomain = {
        _HIHideMenuBar = false;
      };
    };
  };

  homelab = {
    role = "desktop";

    networking = {
      hostName = "work-okta";
    };

    # Work-only SSH key — personal keys excluded from this machine
    primaryUser = {
      userName = "masood.ahmed";
      sshPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPACCnG604Keu/TxyHknYuzLhua3i6FpXw1Jz6TkEoH6 masood.ahmed@okta.com"
      ];
    };

    programs = {
      emacs = {
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
