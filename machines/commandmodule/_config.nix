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
        claude-code = {
          enable = true;
        };
        emacs = {
          enable = true;
        };
        git = {
          enable = true;
        };
        neovim = {
          enable = true;
        };

        motd = {
          enable = true;

          networkInterfaces = [
            "enp0s31f6"
            "wlp0s20f3"
          ];
        };
      };
    };
  };
}
