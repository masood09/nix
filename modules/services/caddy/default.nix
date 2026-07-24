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
  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
in {
  imports = [
    ./alloy.nix
    ./options.nix
  ];

  config = lib.mkIf caddyEnabled {
    services = {
      caddy = {
        enable = true;

        # Global options:
        #  - `metrics` exposes Prometheus metrics on the admin API endpoint
        #    (127.0.0.1:2019/metrics); `per_host` adds a host label so request
        #    rate / status classes / latency break down per virtualHost. Scraped
        #    by ./alloy.nix.
        #  - The `access_journal` named logger tees every site's access log to
        #    stderr as JSON, so it lands in the caddy.service journal and is
        #    shipped to Loki by the existing loki.source.journal. NixOS already
        #    writes per-host access logs to files under services.caddy.logDir
        #    (/var/log/caddy); this is additive — the `include` sink captures the
        #    same http.log.access.* entries without touching the 18 per-vhost
        #    definitions or their file loggers.
        globalConfig = ''
          metrics {
            per_host
          }

          log access_journal {
            output stderr
            format json
            include http.log.access
          }
        '';
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

        certs = {
          ${config.networking.domain} = {
            extraDomainNames = [
              "${config.networking.domain}"
              "*.${config.networking.domain}"
            ];
          };
        };
      };
    };

    # ZFS-managed ACME state dir
    homelab = {
      zfs = {
        datasets = {
          acme = lib.mkIf acmeCfg.zfs.enable {
            inherit (acmeCfg.zfs) dataset properties;

            enable = true;
            mountpoint = "/var/lib/acme";

            # Ensure it exists before units that might touch ACME state
            requiredBy = [
              "caddy.service"
              "acme.service"
            ];
          };
        };
      };
    };

    # Make systemd enforce the mount is present
    systemd = {
      services = lib.mkIf acmeCfg.zfs.enable {
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
    };

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = acmeCfg.zfs.enable;
      directories = ["/var/lib/acme"];
    };

    networking = {
      firewall = {
        allowedTCPPorts = [
          80
          443
        ];
      };
    };
  };
}
