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
    ./alloy.nix
  ];

  options.homelab.services = {
    acme = {
      cloudflareAPIKeyPath = lib.mkOption {
        type = lib.types.path;
        default = config.sops.secrets."cloudflare-api-key".path;
        description = "File containing the Cloudflare API Token.";
      };

      zfs = {
        enable = lib.mkEnableOption "Store /var/lib/acme on a ZFS dataset.";

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
          email = "letsencrypt@mantannest.com";
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          dnsResolver = "1.1.1.1:53";
          credentialFiles = {
            "CLOUDFLARE_DNS_API_TOKEN_FILE" = homelabCfg.services.acme.cloudflareAPIKeyPath;
          };
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
