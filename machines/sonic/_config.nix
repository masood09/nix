# Homelab options — ThinkPad T14 Gen 3 laptop with Niri desktop, bluetooth, fingerprint.
{
  config = {
    homelab = {
      role = "desktop";
      purpose = "Sonic Laptop (NixOS Desktop)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "sonic";
        wireless_enable = true;
      };

      desktop = {
        enable = true;

        niri = {
          enable = true;
        };

        noctalia = {
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

      primaryUser = {
        userId = 1001;
        userName = "zainahmed";
      };

      programs = {
        emacs = {
          enable = true;
        };
        fish = {
          enable = true;
        };
        git = {
          enable = true;
          userName = "Zain Ahmed";
          userEmail = "zain@ahmedmasood.com";
          githubUsername = "zainahmed";
        };
        kitty = {
          enable = true;
        };
        neovim = {
          enable = true;
        };

        motd = {
          enable = true;

          networkInterfaces = [
            "enp1s0"
            "wlp2s0"
          ];
        };

        stylix = {
          scheme = ../../nix/themes/sonic-dark.yaml;
          polarity = "dark";
          wallpaper = ../../nix/wallpapers/sonic-the-hedgehog-3840x2160.jpg;
        };

        zen = {
          enable = true;
          containerProfile = "family";
        };
      };
    };
  };
}
