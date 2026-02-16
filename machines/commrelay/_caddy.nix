{
  config,
  lib,
  ...
}: let
  caddyEnabled = config.services.caddy.enable;
  matrixCfg = config.homelab.services.matrix;

  clientConfig = {
    "m.homeserver".base_url = "https://${matrixCfg.rootDomain}";
    "org.matrix.msc4143.rtc_foci" = [
      {
        type = "livekit";
        livekit_service_url = "https://rtc.${matrixCfg.rootDomain}";
      }
    ];
  };

  serverConfig."m.server" = "${matrixCfg.rootDomain}:443";
in {
  config = lib.mkIf caddyEnabled {
    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${matrixCfg.rootDomain}" = {
            useACMEHost = matrixCfg.rootDomain;
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
              reverse_proxy @masAuth http://100.64.0.21:${toString matrixCfg.synapse.mas.http.web.port}

              @health path /-/health
              reverse_proxy @health http://100.64.0.21:${toString matrixCfg.synapse.listenPort} {
                rewrite /health
              }

              @synapse path /_matrix* /_synapse/client* /_synapse/mas*
              reverse_proxy @synapse http://100.64.0.21:${toString matrixCfg.synapse.listenPort}
            '';
          };

          "mas.${matrixCfg.rootDomain}" = {
            useACMEHost = matrixCfg.rootDomain;
            extraConfig = ''
              @health path /-/health
              reverse_proxy @health http://100.64.0.21:${toString matrixCfg.synapse.mas.http.health.port} {
                rewrite /health
              }

              reverse_proxy http://100.64.0.21:${toString matrixCfg.synapse.mas.http.web.port}
            '';
          };
        };
      };
    };

    security = {
      acme.certs."${matrixCfg.rootDomain}" = {
        extraDomainNames = [
          "${matrixCfg.rootDomain}"
          "*.${matrixCfg.rootDomain}"
        ];
      };
    };
  };
}
