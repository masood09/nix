{lib, ...}: {
  options.homelab.services.acme = {
    enable = lib.mkEnableOption "Whether to enable ACME service.";

    cloudflareAPIKeyPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File containing the Cloudflare API Token.
      '';
    };
  };
}
