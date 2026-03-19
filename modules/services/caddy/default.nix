# Caddy — reverse proxy with automatic HTTPS via ACME (Cloudflare DNS challenge).
# Provisions a wildcard cert for *.domain and individual service virtualHosts
# are added by each service module when caddy is enabled.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  caddyEnabled = homelabCfg.services.caddy.enable;
  acmeCfg = homelabCfg.services.acme;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf caddyEnabled {
    services = {
      caddy = {
        enable = true;
      };
    };

    security = {
      acme = {
        acceptTerms = true;

        defaults = {
          email = "letsencrypt@${config.networking.domain}";
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          dnsResolver = "1.1.1.1:53";
          credentialFiles = {
            "CLOUDFLARE_DNS_API_TOKEN_FILE" = homelabCfg.services.acme.cloudflareAPIKeyPath;
          };
        };

        certs.${config.networking.domain} = {
          extraDomainNames = [
            "${config.networking.domain}"
            "*.${config.networking.domain}"
          ];
        };
      };
    };

    # ZFS-managed ACME state dir
    homelab.zfs.datasets.acme = lib.mkIf acmeCfg.zfs.enable {
      inherit (acmeCfg.zfs) dataset properties;

      enable = true;
      mountpoint = "/var/lib/acme";

      # Ensure it exists before units that might touch ACME state
      requiredBy = [
        "caddy.service"
        "acme.service"
      ];
    };

    # Make systemd enforce the mount is present
    systemd.services = lib.mkIf acmeCfg.zfs.enable {
      caddy = {
        # Unit-level ordering / mount requirements
        unitConfig = {
          RequiresMountsFor = ["/var/lib/acme"];
        };

        requires = ["zfs-dataset-acme.service"];
        after = ["zfs-dataset-acme.service"];
      };

      acme-setup = {
        # Unit-level ordering / mount requirements
        unitConfig = {
          RequiresMountsFor = ["/var/lib/acme"];
        };

        requires = ["zfs-dataset-acme.service"];
        after = ["zfs-dataset-acme.service"];
      };
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !acmeCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          "/var/lib/acme"
        ];
      };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
