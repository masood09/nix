# Security — sudo policy, PAM, and system limits.
# Desktops require a password (or fingerprint) for sudo; servers are passwordless.
{config, ...}: {
  security = {
    sudo.wheelNeedsPassword = config.homelab.role == "desktop";

    pam.services.sudo.fprintAuth = config.homelab.hardware.fingerprint.enable;

    # Raise file descriptor limit for services like databases and containers
    pam.loginLimits = [
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
}
