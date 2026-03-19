# work-pantheon — work macOS machine. Uses GPG signing (not SSH) and
# work-only SSH keys (no personal keys on this machine).
{lib, ...}: {
  imports = [
    ./hardware-configuration.nix

    ./../../modules/macos/base.nix
    ./../../modules/home-manager

    ./_dock.nix
    ./_packages.nix
  ];

  nixpkgs.overlays = [
    (import ../../nix/overlays/darwin-setproctitle.nix)
  ];

  homelab = {
    role = "desktop";

    networking = {
      hostName = "work-pantheon";
    };

    # Work-only SSH key — personal keys excluded from this machine
    primaryUser = {
      sshPublicKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPACCnG604Keu/TxyHknYuzLhua3i6FpXw1Jz6TkEoH6 masoodahmed@pantheon.io"
      ];
    };

    programs = {
      emacs.enable = true;

      git = {
        userEmail = "masoodahmed@pantheon.io";
        enable = true;

        # GPG signing with hardware key for work commits
        signing = {
          method = "gpg";
          gpgKey = "27F12F49A6098D65";
        };
      };

      gpg = {
        enable = true;
      };

      neovim.enable = true;
    };
  };

  system = {
    defaults = {
      universalaccess.reduceMotion = lib.mkForce null;
    };
  };
}
