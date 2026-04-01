# Homelab options — ThinkPad T14 Gen 3 laptop with Niri desktop, bluetooth, fingerprint.
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

        fingerprint = {
          enable = true;
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
