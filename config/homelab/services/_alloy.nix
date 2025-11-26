{lib, ...}: {
  options.homelab.services.alloy = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.boolean;
      description = ''
        Whether to enable Grafana Alloy.
      '';
    };
  };
}
