# Security — sudo policy, PAM, and system limits.
# Desktops require a password (or fingerprint) for sudo; servers are passwordless.
{config, ...}: let
  isDesktopLike = builtins.elem config.homelab.role ["desktop" "htpc"];
in {
  security = {
    sudo = {
      # Desktops require password/fingerprint; servers allow passwordless sudo
      wheelNeedsPassword = isDesktopLike;
    };

    pam = {
      services = {
        sudo = {
          # Allow fingerprint auth for sudo when fingerprint reader is enabled
          fprintAuth = config.homelab.hardware.fingerprint.enable;
        };
      };

      # Raise file descriptor limit for services like databases and containers
      loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "65536";
        }
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "65536";
        }
      ];
    };
  };
}
