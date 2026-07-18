# Homelab options — ThinkPad T14 Gen 3 laptop with Niri desktop, bluetooth, gaming.
{
  config = {
    homelab = {
      role = "desktop";
      purpose = "Primary Laptop (NixOS Desktop)";
      isRootZFS = false;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "usul";
        wireless_enable = true;
      };

      desktop = {
        enable = true;

        # Steam, Gamescope, GameMode, Proton-GE, MangoHud. GameMode applies
        # AMD GPU DPM tuning on this machine (see _gaming.nix).
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

        # Leave fingerprint support off on usul. Shared desktop modules gate
        # fprintd and PAM fingerprint auth on this flag, so disabling it keeps
        # the machine on the password-only path. Bitwarden system-auth unlock is
        # no longer tied to this flag — see programs.bitwarden below.
        fingerprint = {
          enable = false;
        };

        graphics = {
          enable = true;

          driver = "amd";
        };
      };

      stylix = {
        wallpaper = ../../nix/wallpapers/cosy-retreat-sunset.png;
      };

      programs = {
        # Central AI registry: install AI tools locally and expose Claude Code
        # and Codex usage in Noctalia's model-usage widget.
        ai_tools = {
          enable = true;
          models = [
            "claude-code"
            "codex"
          ];
          tools = [
            "claude-code"
            "codex"
            "opencode"
          ];
        };
        # Bitwarden system-auth unlock: install the polkit action and grant it
        # silently for the active session so the vault auto-unlocks at launch.
        # Safe here because usul autologins from the boot password and the login
        # keyring is already unlocked by pam_fde_boot_pw.
        bitwarden = {
          systemAuthUnlock = {
            enable = true;
            passwordless = true;
          };
        };
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
