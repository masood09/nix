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
        wallpaper = ../../nix/wallpapers/cosy-retreat-sunset.png;
      };

      programs = {
        # Central AI registry: install opencode locally and expose Codex usage in
        # Noctalia's model-usage widget.
        ai_tools = {
          enable = true;
          models = ["codex"];
          tools = [
            "codex"
            "opencode"
          ];
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

        zen = {
          enable = true;
        };
      };
    };
  };
}
