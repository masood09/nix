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

      stylix = {
        wallpaper = ../../nix/wallpapers/cosy-retreat-sunset.png;
      };

      programs = {
        fastfetch = {
          zpools = ["rpool"];
        };
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
