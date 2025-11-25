{lib, ...}: {
  options.homelab.services.acme = {
    cloudflareAPIKeyPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File containing the Cloudflare API Token.
      '';
    };
  };
}
