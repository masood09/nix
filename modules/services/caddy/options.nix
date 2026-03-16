{
  config,
  lib,
  ...
}: {
  options.homelab.services = {
    acme = {
      cloudflareAPIKeyPath = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets."cloudflare/api-key".path;
        description = "File containing the Cloudflare API Token.";
      };

      zfs = {
        enable = lib.mkEnableOption "Whether to store /var/lib/acme on a ZFS dataset.";

        dataset = lib.mkOption {
          type = lib.types.str;
          default = "rpool/root/var/lib/acme";
          description = "ZFS dataset to create and mount at /var/lib/acme.";
        };

        properties = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            recordsize = "16K";
          };
          description = "ZFS properties for the ACME dataset.";
        };
      };
    };

    caddy = {
      enable = lib.mkEnableOption "Whether to enable Caddy web server.";
    };
  };
}
