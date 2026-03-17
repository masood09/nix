{config, ...}: {
  security = {
    sudo.wheelNeedsPassword = config.homelab.role == "desktop";

    # Allow fingerprint for sudo on desktops with fingerprint enabled
    pam.services.sudo.fprintAuth = config.homelab.hardware.fingerprint.enable;

    # Increase system-wide file descriptor limit
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
