# Homelab options — ThinkPad T14 Gen 3 laptop with Niri desktop, bluetooth.
{
  config = {
    homelab = {
      role = "desktop";
      purpose = "Primary Laptop (NixOS Desktop)";
      isRootZFS = false;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "arrakis";
        wireless_enable = true;
      };

      desktop = {
        enable = true;

        niri = {
          enable = true;
        };
      };

      hardware = {
        audio = {
          enable = true;
        };

        bluetooth = {
          enable = true;
        };

        # Leave fingerprint support off on arrakis. Shared desktop modules gate
        # fprintd, PAM fingerprint auth, and Bitwarden's polkit action on this
        # flag, so disabling it keeps the machine on the password-only path.
        fingerprint = {
          enable = false;
        };

        graphics = {
          enable = true;

          driver = "amd";
        };
      };

      stylix = {
        enable = true;
        wallpaper = ../../nix/wallpapers/cosy-retreat-sunset.png;
      };

      programs = {
        claude-code = {
          enable = true;
        };
        codex-cli = {
          enable = true;
        };
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
  };
}
