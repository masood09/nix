# Homelab options — ThinkPad T490 laptop with Niri desktop, bluetooth, fingerprint.
{
  config = {
    homelab = {
      role = "desktop";
      purpose = "Sonic Laptop (NixOS Desktop)";

      # Storage stack: LUKS-encrypted ext4 (LVM) + systemd-boot + Plymouth.
      # Setting isRootZFS = false (with role = "desktop" and isEncryptedRoot = true)
      # cascades through shared modules to enable: systemd-boot + systemd initrd
      # + Plymouth splash (modules/nixos/_boot.nix), tmpfs root with /home
      # bind-mounted from /nix/persist (modules/nixos/_impermanence.nix), and
      # greetd auto-login + pam_fde_boot_pw GNOME Keyring unlock for the
      # primary user (modules/nixos/desktop/_greetd.nix). For the keyring
      # auto-unlock to work, zainahmed's login password must equal the LUKS
      # passphrase set during install.
      isRootZFS = false;
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

          driver = "intel";
        };
      };

      primaryUser = {
        userId = 1001;
        userName = "zainahmed";
      };

      stylix = {
        scheme = ../../nix/themes/sonic-dark.yaml;
        polarity = "dark";
        wallpaper = ../../nix/wallpapers/sonic-the-hedgehog-3840x2160.jpg;
      };

      programs = {
        element-desktop = {
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

        zen = {
          enable = true;
        };
      };
    };
  };
}
