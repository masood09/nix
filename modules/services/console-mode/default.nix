# console-mode — gaming vs inference on a GPU shared by Strata and the Steam
# session, decided by a Home Assistant binary_sensor:
#
#   gaming     the Steam/gamescope session runs; Strata is stopped and held
#   inference  the Steam session is stopped; Strata runs
#
# One marker file is the mode: /run/console-mode/gaming exists = gaming. The
# units enforce it themselves, so nothing else has to cooperate:
#   - strata.service and strata-update skip while it exists (Strata's
#     holdFile ExecCondition), whoever starts them; apply_gaming also stops a
#     strata-update already running, because the hold only blocks later
#     starts, and the update's test start would load the model beside the
#     session
#   - model-router refuses Strata requests with 503 backend_held while it
#     exists (its hold follows Strata's holdFile)
#   - display-manager.service only starts while it exists
#     (ConditionPathExists), so the session is down in inference mode,
#     including during TV standby, where its HDMI hotplugs crashed gamescope
# Boot wipes /run, so a host always boots into inference; the controller then
# applies whatever Home Assistant says.
#
# The controller polls the entity. "on" applies gaming once it has held for
# gamingDelay, and "off" applies inference once it has held for
# inferenceDelay; anything else (unavailable, unknown, HTTP or network
# failure) changes nothing and restarts the wait for "on". It runs as its own user,
# with a polkit rule for start/stop on exactly the units it manages.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.console-mode;
  strataCfg = homelabCfg.services.strata;

  runDirName = "console-mode";
  marker = "/run/${runDirName}/gaming";

  sessionUser = homelabCfg.desktop.gaming.user;
  sessionUid = config.users.users.${sessionUser}.uid or null;
  # The session's user manager is where Steam and gamescope run; stopping
  # display-manager alone would leave them behind.
  sessionUnits = [
    "display-manager.service"
    "user@${toString sessionUid}.service"
  ];
  # Only when the timer unit exists: a stop of a unit with no unit file
  # fails, and apply_gaming would retry it forever.
  updateUnits = lib.optionals strataCfg.autoUpdate.enable [
    "strata-update.service"
  ];
  managedUnits = ["strata.service"] ++ updateUnits ++ sessionUnits;

  controller = pkgs.writeShellApplication {
    name = "console-mode";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
      pkgs.systemd
    ];
    text = ''
      url=${lib.escapeShellArg "${cfg.homeAssistant.url}/api/states/${cfg.homeAssistant.entity}"}
      header=${lib.escapeShellArg cfg.homeAssistant.headerFile}
      marker=${lib.escapeShellArg marker}
      delay=${toString cfg.inferenceDelay}
      gaming_delay=${toString cfg.gamingDelay}
      after_gaming_start=${
        if cfg.startStrataAfterGaming
        then "yes"
        else "no"
      }
      session_units=(${lib.escapeShellArgs sessionUnits})
      update_units=(${lib.escapeShellArgs updateUnits})

      # Only changes are logged, so a long Home Assistant outage is one line.
      last_note=""
      note() {
        if [ "$1" != "$last_note" ]; then
          echo "$1"
          last_note="$1"
        fi
      }

      # An apply that fails (polkit restarting during a switch, a unit that
      # will not stop) is retried every retry_delay seconds, not every poll,
      # until it succeeds. asserted is set only by a complete apply.
      retry_delay=30
      retry_at=0
      applied() {
        if [ "$1" = ok ]; then
          asserted=1
        else
          asserted=""
          retry_at=$(($(date +%s) + retry_delay))
          echo "$mode mode is incomplete; retrying in ''${retry_delay}s" >&2
        fi
      }
      # True when the current mode still has to be (re)applied.
      due() {
        [ -z "$asserted" ] && [ "$(date +%s)" -ge "$retry_at" ]
      }

      apply_gaming() {
        local ok=ok
        echo "gaming mode: holding and stopping Strata, starting the Steam session"
        # Marker first: it holds Strata and model-router, and
        # display-manager's start condition needs it.
        touch "$marker"
        # An update already running would test-start the new engine on the
        # GPU beside the session: the hold only blocks later starts, so stop
        # it here. Its ExecStopPost (root) tries to restore Strata, which the
        # hold skips. Upstream stages a new engine and switches to it only
        # after a passing test start, so a stop mid-run leaves the old engine.
        local unit
        for unit in "''${update_units[@]}"; do
          systemctl stop "$unit" || { echo "stopping $unit failed" >&2; ok=fail; }
        done
        systemctl stop strata.service || { echo "stopping Strata failed" >&2; ok=fail; }
        systemctl start display-manager.service || { echo "starting the Steam session failed" >&2; ok=fail; }
        applied "$ok"
      }

      # $1 = "no": leave Strata stopped (leaving gaming mode on a host that
      # suspends when idle; it starts Strata itself on its next wake).
      apply_inference() {
        local ok=ok start="''${1:-yes}"
        if [ "$start" = no ]; then
          echo "inference mode: stopping the Steam session, leaving Strata stopped"
        else
          echo "inference mode: stopping the Steam session, starting Strata"
        fi
        # One unit per call: with several units, systemctl (systemd 262)
        # enqueues them as one batch whose polkit check carries no single
        # unit name, so the per-unit rule cannot allow it ("Failed to
        # enqueue jobs: Access denied").
        local unit
        for unit in "''${session_units[@]}"; do
          if ! systemctl stop "$unit"; then
            # The marker stays, so the session keeps its claim on the GPU
            # and Strata stays held until the stop succeeds.
            echo "stopping $unit failed" >&2
            applied fail
            return
          fi
        done
        # Load-bearing order: Strata's ExecCondition is evaluated when it
        # starts, and a start skipped by it still exits 0. Removing the
        # marker after the start would leave Strata silently stopped.
        rm -f "$marker"
        if [ "$start" = no ]; then
          applied "$ok"
          return
        fi
        # --no-block: Strata's ExecStartPre can regenerate a run config for
        # minutes, and the loop must keep watching Home Assistant meanwhile.
        systemctl start --no-block strata.service || { echo "starting Strata failed" >&2; ok=fail; }
        sleep 2
        case "$(systemctl show -p ActiveState --value strata.service)" in
          active | activating) ;;
          *) echo "Strata did not come up; see journalctl -u strata" >&2 ;;
        esac
        applied "$ok"
      }

      # The marker says which mode the host is in. The first answer from Home
      # Assistant is applied in full even if it matches, so the units converge
      # after a restart of this unit or on its first deploy. Until Home
      # Assistant answers, nothing is touched: asserting the marker's mode
      # first could stop a running game only to start it again moments later.
      if [ -e "$marker" ]; then
        mode=gaming
      else
        mode=inference
      fi
      asserted=""

      off_since=""
      on_since=""
      while :; do
        if body="$(curl -fsS -m 5 -H @"$header" "$url" 2>&1)"; then
          state="$(jq -r '.state // empty' <<<"$body" 2>/dev/null || true)"
        else
          note "could not read Home Assistant, keeping $mode mode: $body"
          state=""
        fi
        case "$state" in
          on)
            note "entity on"
            off_since=""
            if [ "$mode" != gaming ]; then
              # Only an "on" that holds counts: a brief one (the sync box
              # jumping inputs while ixian wakes) must not stop Strata.
              now="$(date +%s)"
              on_since="''${on_since:-$now}"
              if [ $((now - on_since)) -ge "$gaming_delay" ]; then
                mode=gaming
                on_since=""
                apply_gaming
              fi
            elif due; then
              apply_gaming
            fi
            ;;
          off)
            note "entity off"
            on_since=""
            if [ "$mode" = gaming ]; then
              # The delay applies to a restart in gaming mode too, so a quick
              # flip during a deploy does not reload Strata.
              now="$(date +%s)"
              off_since="''${off_since:-$now}"
              if [ $((now - off_since)) -ge "$delay" ]; then
                mode=inference
                off_since=""
                apply_inference "$after_gaming_start"
              fi
            elif due; then
              apply_inference
            fi
            ;;
          "") ;;
          *)
            note "entity is $state, keeping $mode mode"
            on_since=""
            ;;
        esac
        sleep ${toString cfg.interval}
      done
    '';
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = strataCfg.enable;
        message = "homelab.services.console-mode hands the GPU between Strata and the Steam session: enable homelab.services.strata.";
      }
      {
        assertion = config.services.displayManager.enable;
        message = "homelab.services.console-mode runs the Steam session through display-manager.service: enable a display manager.";
      }
      {
        assertion = sessionUid != null;
        message = "homelab.services.console-mode needs ${sessionUser} (homelab.desktop.gaming.user) to be a declared account with a fixed uid, to stop its user manager.";
      }
    ];

    homelab = {
      services = {
        strata = {
          holdFile = marker;
        };
      };
    };

    users = {
      users = {
        console-mode = {
          isSystemUser = true;
          group = "console-mode";
          uid = cfg.userId;
        };
      };

      groups = {
        console-mode = {
          gid = cfg.groupId;
        };
      };
    };

    # Only start/stop, only these units, only for this user. One entry is
    # another account's user manager (the gaming user's), which this user
    # stops to end the Steam session; it is named concretely. strata-update
    # joins the list only when its timer unit exists.
    security = {
      polkit = {
        enable = true;
        extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                subject.user == "console-mode" &&
                ${builtins.toJSON managedUnits}.indexOf(action.lookup("unit")) >= 0 &&
                ["start", "stop"].indexOf(action.lookup("verb")) >= 0) {
              return polkit.Result.YES;
            }
          });
        '';
      };
    };

    systemd = {
      services = {
        # graphical.target wants display-manager, so leaving the session out of
        # inference mode needs a condition rather than an empty wantedBy. A
        # session that crashes in gaming mode is still restarted; once the
        # marker is gone, a stop stays stopped.
        display-manager = {
          unitConfig = {
            ConditionPathExists = marker;
          };
        };

        console-mode = {
          description = "Switch between gaming and inference following Home Assistant";
          wantedBy = [
            "multi-user.target"
          ];
          # After polkit: every systemctl call is authorized by it, and a switch
          # restarts both units together. The apply retry covers the rest.
          after = [
            "network-online.target"
            "polkit.service"
          ];
          wants = [
            "network-online.target"
          ];
          serviceConfig = {
            User = "console-mode";
            Group = "console-mode";
            ExecStart = lib.getExe controller;
            # 0755 so strata and model-router can test for the marker.
            # Preserve=yes keeps the mode across a stop and start of this
            # unit (a switch stops changed services); boot still wipes /run.
            RuntimeDirectory = runDirName;
            RuntimeDirectoryMode = "0755";
            RuntimeDirectoryPreserve = "yes";
            Restart = "always";
            RestartSec = 10;
            # A stop can wait on Strata's drain (TimeoutStopSec 90 s) or the
            # session stop (user@.service allows 120 s).
            TimeoutStopSec = 150;

            NoNewPrivileges = true;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictAddressFamilies = [
              "AF_UNIX"
              "AF_INET"
              "AF_INET6"
            ];
            CapabilityBoundingSet = "";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            RestrictNamespaces = true;
            RestrictRealtime = true;
            SystemCallArchitectures = "native";
          };
        };
      };
    };
  };
}
