# SearXNG — privacy-respecting metasearch engine.
# Runs the upstream services.searx module inside the nixflix WireGuard network
# namespace (VPN-Confinement), so every outbound request — engine queries, image
# proxy fetches, DNS — leaves through the Proton VPN. Caddy on the host fronts it.
#
# Do NOT point SearXNG at FlareSolverr: homelab.services.arr.flaresolverr runs on
# the host network, so routing requests through it would leak egress around the VPN.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.searxng;
  searxCfg = config.services.searx;
  ns = cfg.vpn.namespace;
  nsCfg = config.vpnNamespaces.${ns};
  caddyEnabled = config.services.caddy.enable;

  # Upstream only sets restartTriggers in its uwsgi branch, so in this
  # (non-uwsgi) mode a settings change would otherwise not restart anything.
  # Both units need it: searx-init is a RemainAfterExit oneshot that renders
  # /run/searx/settings.yml, and searx only reads settings at process start.
  settingsTriggers = [
    (builtins.toJSON searxCfg.settings)
    (builtins.toJSON searxCfg.limiterSettings)
  ];
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.nixflix.vpn.enable;
        message = "homelab.services.searxng requires nixflix.vpn.enable; without the WireGuard namespace SearXNG would egress on the host network.";
      }
      {
        # A host-firewall opening would bypass Caddy, and with it the
        # X-Forwarded-For handling the limiter depends on.
        assertion = !(builtins.elem cfg.listenPort config.networking.firewall.allowedTCPPorts);
        message = "homelab.services.searxng: port ${toString cfg.listenPort} must not be opened in the host firewall; reach SearXNG through Caddy.";
      }
    ];

    users = {
      users = {
        searx = {
          isSystemUser = true;
          group = "searx";
          uid = cfg.userId;
        };
      };

      groups = {
        searx = {
          gid = cfg.groupId;
        };
      };
    };

    sops = {
      templates = {
        "searxng.env" = {
          content = ''
            SEARXNG_SECRET=${config.sops.placeholder."searxng/secret-key"}
          '';
          owner = "searx";
          group = "searx";
          mode = "0400";
          # searx-init re-renders settings.yml (envsubst) before searx restarts.
          restartUnits = [
            "searx-init.service"
            "searx.service"
          ];
        };
      };
    };

    services = {
      searx = {
        enable = true;
        # Valkey over a unix socket (/run/redis-searx/redis.sock); filesystem
        # sockets are not network-namespaced, so it works from inside the netns.
        # The module derives settings.valkey.url — don't set it by hand.
        redisCreateLocally = true;
        environmentFile = config.sops.templates."searxng.env".path;

        settings = {
          use_default_settings = {
            engines = {
              keep_only = cfg.engines;
            };
          };

          # keep_only only filters; it doesn't re-enable engines upstream ships
          # with `disabled: true` (mojeek, qwant, nixos wiki). With
          # use_default_settings, these entries merge into the defaults by name.
          engines =
            map (name: {
              inherit name;
              disabled = false;
            })
            cfg.engines;

          server = {
            bind_address = "0.0.0.0";
            port = cfg.listenPort;
            base_url = "https://${cfg.webDomain}/";
            # Substituted by searx-init's envsubst into /run/searx/settings.yml,
            # so the secret never lands in the Nix store.
            secret_key = "$SEARXNG_SECRET";
            limiter = true;
            image_proxy = true;
            public_instance = false;
          };

          search = {
            formats = [
              "html"
              "json"
            ];
          };
        };

        limiterSettings = {
          botdetection = {
            # Only Caddy's source address (the host side of the netns bridge).
            # Caddy sends X-Forwarded-For with one trusted hop.
            trusted_proxies = [
              nsCfg.bridgeAddress
            ];
          };
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            # The netns DNAT rules are PREROUTING-only, so host-local Caddy can't
            # use 127.0.0.1:<port>; it must target the namespace address directly.
            extraConfig = ''
              reverse_proxy http://${nsCfg.namespaceAddress}:${toString cfg.listenPort}
            '';
          };
        };
      };
    };

    # The netns INPUT policy is DROP; this mapping generates the only accept rule
    # for the SearXNG port. The host firewall stays closed for it.
    vpnNamespaces = {
      ${ns} = {
        portMappings = [
          {
            from = cfg.listenPort;
            to = cfg.listenPort;
            protocol = "tcp";
          }
        ];
      };
    };

    systemd = {
      services = {
        # Upstream writes limiterSettings to /etc/searxng/limiter.toml, but SearXNG
        # (searx/limiter.py) reads limiter.toml from the directory holding
        # SEARXNG_SETTINGS_PATH, i.e. /run/searx. Without this link the limiter
        # config is silently ignored and every client appears as the bridge IP.
        # Done here rather than via tmpfiles because searx-init owns /run/searx
        # (RuntimeDirectory, created before ExecStartPre), so there's no ordering
        # race. Guarded like upstream's /etc entry so the link can't dangle.
        searx-init = {
          restartTriggers = settingsTriggers;

          serviceConfig = {
            ExecStartPre = lib.mkIf (searxCfg.limiterSettings != {}) [
              "${lib.getExe' pkgs.coreutils "ln"} -sfn /etc/searxng/limiter.toml /run/searx/limiter.toml"
            ];
          };
        };

        searx = {
          requires = ["redis-searx.service"];
          after = ["redis-searx.service"];
          restartTriggers = settingsTriggers;

          vpnConfinement = {
            enable = true;
            vpnNamespace = ns;
          };
        };
      };
    };
  };
}
