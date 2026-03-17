{
  config.homelab = {
    role = "desktop";
    purpose = "Primary Laptop (NixOS Desktop)";
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "commandmodule";
      wireless_enable = true;
    };

    desktop.niri.enable = true;

    hardware.bluetooth.enable = true;
    hardware.fingerprint.enable = true;

    programs = {
      claude-code.enable = true;
      emacs.enable = true;
      git.enable = true;
      neovim.enable = true;

      motd = {
        enable = true;

        networkInterfaces = [
          "enp0s31f6"
          "wlp0s20f3"
        ];
      };
    };
  };
}
