# Homelab options — ThinkPad laptop with Niri desktop, bluetooth, fingerprint.
{
  config = {
    homelab = {
      role = "desktop";
      purpose = "Primary Laptop (NixOS Desktop)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "commandmodule";
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
        };
      };

      programs = {
        fastfetch = {
          zpools = ["rpool"];
        };
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

        stylix = {
          wallpaper = ../../nix/wallpapers/cosy-retreat-sunset.png;
        };

        zen = {
          enable = true;
        };
      };
    };
  };
}
