# Homelab options — ThinkPad T490 laptop with Niri desktop, bluetooth, fingerprint, gaming.
# Dual-user machine: zainahmed (desktop, no sudo) + masoodahmed (sudo/SSH admin, no desktop).
{lib, ...}: {
  config = {
    # Passwordless sudo for wheel — masoodahmed administers via SSH (server-style).
    # zainahmed is not in wheel, so this has no effect on the desktop user.
    security = {
      sudo = {
        wheelNeedsPassword = lib.mkForce false;
      };
    };

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

      # Only masoodahmed can SSH in — zainahmed is a local desktop-only user.
      services = {
        ssh = {
          allowUsers = ["masoodahmed"];
        };
      };

      desktop = {
        enable = true;

        # Steam, Gamescope, GameMode, Proton-GE, MangoHud. GameMode GPU
        # tuning is skipped on Intel iGPUs (see _gaming.nix).
        gaming = {
          enable = true;
        };

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

      # Desktop-only user — no sudo. Retains networkmanager, audio, input,
      # video groups for full desktop functionality (WiFi, sound, brightness,
      # fingerprint). Admin tasks are handled by masoodahmed (see _users.nix).
      primaryUser = {
        userId = 1001;
        userName = "zainahmed";
        wheel = false;
      };

      stylix = {
        scheme = ../../nix/themes/sonic-dark.yaml;
        polarity = "dark";
        wallpaper = ../../nix/wallpapers/sonic-the-hedgehog-3840x2160.jpg;
      };

      programs = {
        # Bitwarden system-auth unlock: install the polkit action and grant it
        # silently for the active session so the vault auto-unlocks at launch.
        # Safe here because sonic autologins from the boot password (password
        # login path) and the login keyring is already unlocked by
        # pam_fde_boot_pw. Note: passwordless bypasses the fingerprint prompt too.
        bitwarden = {
          systemAuthUnlock = {
            enable = true;
            passwordless = true;
          };
        };
        element-desktop = {
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
        prism-launcher = {
          enable = true;
        };

        zen = {
          enable = true;
        };
      };
    };
  };
}
