# model-router — OpenAI-compatible proxy that switches Strata's model size per
# request. The app (github.com/masood09/model-router, flake input
# `model-router`) is generic; this wrapper renders the homelab's catalog into
# its settings and wires it to Strata:
#
#   client -> model-router (listenPort) -> Strata (homelab.services.strata.listenPort)
#
# Catalog: for every size, "<prefix><size>" sets experimental_speed_projection
# false and "<prefix><size><uncensoredSuffix>" sets it true (only when the
# request does not set it). Both names share one loaded model, so they never
# switch. A request for another size waits until in-flight requests finish,
# then model-router writes the size to selectionFile and restarts
# strata.service (allowed by a polkit rule for this user and unit only);
# Strata's configure reads the file at start. Names outside the catalog are
# served by whatever is loaded and never switch.
#
# Exposure: loopback by default. A host that lets LiteLLM reach it over the
# tailnet listens on 0.0.0.0 with the port open on tailscale0 only, and sets
# clientTokensFile so the router refuses requests without the backend key
# (the Headscale ACL is the other gate). Caddy's ai.<domain> still points
# straight at Strata until the clients move to LiteLLM.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.model-router;
  strataCfg = homelabCfg.services.strata;
  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};

  modelsFor = size: {
    "${cfg.namePrefix}${size}" = {
      backend = "strata";
      variant = size;
      inject = {
        experimental_speed_projection = false;
      };
    };
    "${cfg.namePrefix}${size}${cfg.uncensoredSuffix}" = {
      backend = "strata";
      variant = size;
      inject = {
        experimental_speed_projection = true;
      };
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = strataCfg.enable;
        message = "homelab.services.model-router drives Strata: enable homelab.services.strata on this host.";
      }
      {
        assertion = lib.all (s: lib.elem s ([strataCfg.model] ++ strataCfg.models)) cfg.sizes;
        message = "homelab.services.model-router.sizes must be Strata sizes (homelab.services.strata.model/models).";
      }
      {
        assertion = strataCfg.selectionFile == cfg.selectionFile;
        message = "homelab.services.strata.selectionFile must be model-router's selectionFile (${cfg.selectionFile}).";
      }
      {
        assertion = strataCfg.experimentalSpeedProjection;
        message = "model-router's -uncensored names need homelab.services.strata.experimentalSpeedProjection.";
      }
      {
        assertion = lib.elem cfg.listenAddress ["127.0.0.1" "::1" "localhost"] || cfg.clientTokensFile != null;
        message = "homelab.services.model-router listens on ${cfg.listenAddress}: set clientTokensFile, or anyone on that network can switch Strata.";
      }
    ];

    networking = {
      firewall = lib.mkIf cfg.openFirewall (
        if cfg.firewallInterfaces == []
        then {
          allowedTCPPorts = [cfg.listenPort];
        }
        else {
          interfaces = lib.genAttrs cfg.firewallInterfaces (_: {
            allowedTCPPorts = [cfg.listenPort];
          });
        }
      );
    };

    homelab = {
      services = {
        strata = {
          selectionFile = lib.mkDefault cfg.selectionFile;
        };
      };
    };

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      directories = [
        {
          directory = "/var/lib/model-router";
          user = "model-router";
          group = "model-router";
          mode = "0755";
        }
      ];
    };

    services = {
      model-router = {
        enable = true;
        uid = cfg.userId;
        gid = cfg.groupId;
        polkit = {
          units = ["strata.service"];
          verbs = ["restart" "stop"];
        };
        settings = {
          listen = "${cfg.listenAddress}:${toString cfg.listenPort}";
          defaultModel = "${cfg.namePrefix}${strataCfg.model}";
          unknownModel = "loaded";
          passthrough = "default";
          log = {
            level = "info";
          };
          auth = lib.mkIf (cfg.clientTokensFile != null) {
            inherit (cfg) clientTokensFile;
            adminTokensFile = cfg.clientTokensFile;
          };
          groups = {
            gpu0 = {
              inherit (cfg) maxWait;
              stateRefresh = "15s";
            };
          };
          backends = {
            strata = {
              group = "gpu0";
              upstream = "http://${strataCfg.listenAddress}:${toString strataCfg.listenPort}";
              driver = {
                kind = "systemd";
                systemd = {
                  unit = "strata.service";
                  inherit (cfg) selectionFile;
                  defaultVariant = strataCfg.model;
                  actionTimeout = cfg.switchTimeout;
                };
              };
              readiness = {
                path = "/v1/models";
                bodyContains = ''"loaded"'';
                interval = "3s";
                timeout = cfg.switchTimeout;
              };
              # Follows Strata's own hold: while the file exists, Strata
              # cannot start, so the router refuses at once (503
              # backend_held) instead of restarting it and waiting out
              # switchTimeout.
              hold = lib.mkIf (strataCfg.holdFile != null) {
                file = strataCfg.holdFile;
                retryAfter = "60s";
              };
            };
          };
          models = lib.mergeAttrsList (map modelsFor cfg.sizes);
        };
      };
    };
  };
}
