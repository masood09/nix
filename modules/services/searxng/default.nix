# SearXNG — privacy-respecting metasearch engine, fronted by Caddy on the host.
#
# Two egress modes, picked by homelab.services.searxng.vpn.enable:
#   - off: SearXNG runs on the host network, bound to loopback, and engines see
#     the host's public IP.
#   - on: SearXNG joins the nixflix WireGuard namespace (VPN-Confinement), so
#     engine queries, image-proxy fetches and DNS all leave through the VPN.
#     Many engines block or CAPTCHA a shared VPN exit, so expect to trim
#     `engines` in this mode.
#
# Do NOT point SearXNG at FlareSolverr in VPN mode:
# homelab.services.arr.flaresolverr runs on the host network, so routing
# requests through it would leak egress around the VPN.
#
# Limiter (homelab.services.searxng.limiter, on by default): its botdetection
# header filters require browser-shaped requests — Accept must contain text/html
# and Accept-Language must be present — so a programmatic client sending only
# Accept: application/json, such as Hermes' SearXNG provider, is 429'd. Even a
# browser-shaped client is capped on the JSON API: botdetection.ip_limit allows
# 4 non-html requests per hour per network. The narrower fix is
# botdetection.ip_lists.pass_ip, which is checked before those filters, so it
# exempts one client address rather than turning the limiter off for everyone;
# heartbeat disables the limiter instead.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.searxng;
  searxCfg = config.services.searx;
  vpnEnabled = cfg.vpn.enable;
  ns = cfg.vpn.namespace;
  nsCfg = config.vpnNamespaces.${ns};
  caddyEnabled = config.services.caddy.enable;

  # The only proxy the limiter should trust for X-Forwarded-For is the address
  # Caddy connects from: the host side of the netns bridge in VPN mode, loopback
  # in host mode (::1 too, in case Caddy ever reaches loopback over IPv6). The
  # target Caddy connects to is cfg.clientUrl, which the same rule resolves.
  proxyAddresses =
    if vpnEnabled
    then [nsCfg.bridgeAddress]
    else [
      "127.0.0.1"
      "::1"
    ];

  # Many engines block or CAPTCHA the shared VPN exit, so VPN mode uses its
  # own tested list rather than the host-tuned one.
  engines =
    if vpnEnabled
    then cfg.vpnEngines
    else cfg.engines;

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

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          # Guard: SearXNG is only meant to be reached through Caddy. In VPN
          # mode (bound to 0.0.0.0 in the netns) an opening would also bypass
          # the X-Forwarded-For handling the limiter depends on.
          assertion = !(builtins.elem cfg.listenPort config.networking.firewall.allowedTCPPorts);
          message = "homelab.services.searxng: don't open port ${toString cfg.listenPort} in the host firewall; reach SearXNG through Caddy.";
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
          # sockets are not network-namespaced, so this also works in VPN mode.
          # The module derives settings.valkey.url — don't set it by hand.
          redisCreateLocally = true;
          environmentFile = config.sops.templates."searxng.env".path;

          settings = {
            use_default_settings = {
              engines = {
                keep_only = engines;
              };
            };

            # keep_only only filters; it doesn't re-enable engines upstream
            # ships with `disabled: true` (e.g. mojeek, qwant, nixos wiki). With
            # use_default_settings, these entries merge into the defaults by name.
            engines =
              map (name: {
                inherit name;
                disabled = false;
              })
              engines;

            server = {
              # Inside the netns nothing but the mapped port is reachable, so
              # 0.0.0.0 is fine there; on the host, stay on loopback.
              bind_address =
                if vpnEnabled
                then "0.0.0.0"
                else "127.0.0.1";
              port = cfg.listenPort;
              base_url = "https://${cfg.webDomain}/";
              # Substituted by searx-init's envsubst into /run/searx/settings.yml,
              # so the secret never lands in the Nix store.
              secret_key = "$SEARXNG_SECRET";
              inherit (cfg) limiter;
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

          # Gated so nothing is emitted when the limiter is off: upstream only
          # writes limiter.toml when limiterSettings is non-empty, and the
          # ExecStartPre link below is guarded on the same condition.
          limiterSettings = lib.optionalAttrs cfg.limiter {
            botdetection = {
              # Only Caddy's source address. Caddy sends X-Forwarded-For with
              # one trusted hop.
              trusted_proxies = proxyAddresses;
            };
          };
        };

        caddy = lib.mkIf caddyEnabled {
          virtualHosts = {
            "${cfg.webDomain}" = {
              useACMEHost = config.networking.domain;
              extraConfig = ''
                reverse_proxy ${cfg.clientUrl}
              '';
            };
          };
        };
      };

      systemd = {
        services = {
          # Upstream writes limiterSettings to /etc/searxng/limiter.toml, but
          # SearXNG (searx/limiter.py) reads limiter.toml from the directory
          # holding SEARXNG_SETTINGS_PATH, i.e. /run/searx. Without this link the
          # limiter config is silently ignored and every client appears as the
          # proxy's address. Done here rather than via tmpfiles because
          # searx-init owns /run/searx (RuntimeDirectory, created before
          # ExecStartPre), so there's no ordering race. Guarded like upstream's
          # /etc entry so the link can't dangle.
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
          };
        };
      };
    }

    (lib.mkIf vpnEnabled {
      assertions = [
        {
          assertion = config.nixflix.vpn.enable;
          message = "homelab.services.searxng.vpn.enable requires nixflix.vpn.enable; without the WireGuard namespace SearXNG would egress on the host network.";
        }
      ];

      # The netns INPUT policy is DROP; this mapping generates the only accept
      # rule for the SearXNG port. The host firewall stays closed for it.
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
          searx = {
            vpnConfinement = {
              enable = true;
              vpnNamespace = ns;
            };
          };
        };
      };
    })
  ]);
}
