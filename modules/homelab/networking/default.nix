{lib, ...}: {
  options.homelab.networking = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = ''
        The hostname of the machine.
      '';
    };

    dhcpcd_enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };

    useNetworkd = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };

    primaryInterface = lib.mkOption {
      type = lib.types.str;
    };

    tailscaleInterface = lib.mkOption {
      default = "tailscale0";
      type = lib.types.str;
    };

    wireless_enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };

    extraHosts = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "192.168.0.1 lanlocalhost";
      description = ''
        Additional verbatim entries to be appended to {file}`/etc/hosts`.
        For adding hosts from derivation results, use {option}`networking.hostFiles` instead.
      '';
    };
  };
}
