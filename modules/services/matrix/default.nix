{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.matrix;
  caddyEnabled = config.services.caddy.enable;

  clientConfig = {
    "m.homeserver".base_url = "https://${cfg.rootDomain}";
    "org.matrix.msc4143.rtc_foci" = [
      {
        type = "livekit";
        livekit_service_url = "https://rtc.${cfg.rootDomain}";
      }
    ];
  };

  serverConfig."m.server" = "${cfg.rootDomain}:443";
in {
  imports = [
    ./options.nix
    ./synapse.nix
  ];

  config = {
    services = {
      "lk-jwt-service" = lib.mkIf cfg.rtc.enable {
        enable = true;
        keyFile = config.sops.secrets."matrix/lk-jwt-service/keys".path;
        inherit (cfg.rtc."lk-jwt-service") port;
        livekitUrl = "wss://rtc.${cfg.rootDomain}/livekit/sfu";
      };

      livekit = lib.mkIf cfg.rtc.enable {
        enable = true;
        keyFile = config.sops.secrets."matrix/lk-jwt-service/keys".path;
        openFirewall = true;

        settings = {
          bind_addresses = cfg.rtc.livekit.bindAddress;
          inherit (cfg.rtc.livekit.ports) port;

          rtc = {
            tcp_port = cfg.rtc.livekit.ports.tcpPort;
            port_range_start = cfg.rtc.livekit.ports.rtcPortRangeStart;
            port_range_end = cfg.rtc.livekit.ports.rtcPortRangeEnd;
            use_external_ip = cfg.rtc.livekit.rtcExternalIP;
          };

          room = {
            auto_create = false;
          };

          logging = {
            level = "info";
          };

          turn = {
            enabled = false;
          };
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.rootDomain}" = lib.mkIf (cfg.synapse.enable && cfg.synapse.enableCaddy) {
            useACMEHost = cfg.rootDomain;
            extraConfig = ''
              # Server discovery (no CORS required, but harmless)
              handle /.well-known/matrix/server {
                header Content-Type application/json
                respond `${builtins.toJSON serverConfig}` 200
              }

              # Client discovery: MUST include CORS for some validators / browsers
              handle /.well-known/matrix/client {
                header Content-Type application/json
                header Access-Control-Allow-Origin "*"
                header Access-Control-Allow-Methods "GET, OPTIONS"
                header Access-Control-Allow-Headers "Origin, Accept, Content-Type, Authorization"

                # Optional: make preflight happy if anyone ever OPTIONS it
                @options method OPTIONS
                respond @options 204

                respond `${builtins.toJSON clientConfig}` 200
              }

              @masAuth path_regexp masAuth ^/_matrix/client/(.*)/(login|logout|refresh)$
              reverse_proxy @masAuth http://127.0.0.1:${toString cfg.synapse.mas.http.web.port}

              @health path /-/health
              reverse_proxy @health http://127.0.0.1:${toString cfg.synapse.listenPort} {
                rewrite /health
              }

              @synapse path /_matrix* /_synapse/client* /_synapse/mas*
              reverse_proxy @synapse http://127.0.0.1:${toString cfg.synapse.listenPort}
            '';
          };

          "rtc.${cfg.rootDomain}" = lib.mkIf cfg.rtc.enable {
            useACMEHost = cfg.rootDomain;
            extraConfig = ''
              handle /sfu/get* {
                reverse_proxy 127.0.0.1:${toString cfg.rtc."lk-jwt-service".port}
              }

              handle_path /livekit/sfu* {
                reverse_proxy 127.0.0.1:${toString cfg.rtc.livekit.ports.port}
              }
            '';
          };

          "mas.${cfg.rootDomain}" = lib.mkIf (cfg.synapse.enable && cfg.synapse.enableCaddy) {
            useACMEHost = cfg.rootDomain;
            extraConfig = ''
              @health path /-/health
              reverse_proxy @health http://127.0.0.1:${toString cfg.synapse.mas.http.health.port} {
                rewrite /health
              }

              reverse_proxy http://127.0.0.1:${toString cfg.synapse.mas.http.web.port}
            '';
          };
        };
      };
    };

    security = lib.mkIf (caddyEnabled && ((cfg.synapse.enableCaddy && cfg.synapse.enable) || cfg.rtc.enable)) {
      acme.certs."${cfg.rootDomain}" = {
        extraDomainNames = [
          "${cfg.rootDomain}"
          "*.${cfg.rootDomain}"
        ];
      };
    };

    systemd.services = {
      "lk-jwt-service" = lib.mkIf cfg.rtc.enable {
        environment = {
          LIVEKIT_FULL_ACCESS_HOMESERVERS = cfg.rootDomain;
          LIVEKIT_JWT_BIND = "127.0.0.1:${toString cfg.rtc."lk-jwt-service".port}";
          LIVEKIT_JWT_PORT = lib.mkForce "";
        };
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts =
        lib.optionals cfg.synapse.enable [
          cfg.synapse.listenPort
          cfg.synapse.mas.http.web.port
          cfg.synapse.mas.http.health.port
        ]
        ++ lib.optionals cfg.rtc.enable [
          cfg.rtc.livekit.ports.tcpPort
        ];

      allowedUDPPortRanges = lib.optionals cfg.rtc.enable [
        {
          from = cfg.rtc.livekit.ports.rtcPortRangeStart;
          to = cfg.rtc.livekit.ports.rtcPortRangeEnd;
        }
      ];
    };
  };
}
