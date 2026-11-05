# Hermes Agent — Nous Research's self-improving agent, run headless as a
# messaging gateway (Matrix, Discord, Telegram) plus an SSH-side CLI wrapper.
#
# Package: numtide/llm-agents.nix (prebuilt in cache.numtide.com; consumed via
# its own `packages` attr, no overlay/follows — see flake.nix).
#
# Isolation: the gateway runs as an unprivileged `hermes` system user. The
# agent's terminal tool uses Hermes' docker backend, which auto-detects podman;
# containers run as *rootless* podman under that user (own subuid range), so
# the rootful podman socket other services use is never reachable.
#
# What the sandbox covers: only the terminal tool. Container root maps to the
# hermes UID (Hermes adds DAC_OVERRIDE/CHOWN/FOWNER), and the only host paths
# mounted in are /output and a per-task home/workspace under
# HERMES_HOME/sandboxes (writable) plus skills and the media caches
# (read-only). config.yaml, memories, cron jobs and the state DB are not
# mounted, so sandboxed code cannot reach them.
#
# What the sandbox is NOT:
#   - A boundary for anything the gateway runs itself. Hermes' in-process
#     tools (skill management, cron, memory, config), MCP servers and plugins
#     run on the host as the hermes user, outside the container, with the same
#     network reach described below. A prompt-injected turn can use those to
#     plant a skill or cron job that runs later, or to change config.yaml.
#     ExecStartPre re-applies the managed keys below on every start, so a
#     tampered backend or image lasts only until the next restart; planted
#     skills and cron jobs persist.
#   - A credential boundary against skills. Pinning
#     terminal.docker_forward_env = [] stops config drift, but a skill's
#     `required_environment_variables` frontmatter is forwarded into the
#     sandbox independently of that key. A planted SKILL.md declaring
#     MATRIX_ACCESS_TOKEN would put the token in the container the next time
#     the skill loads.
#   - A network boundary (accepted risk). Commands get full egress through
#     pasta, which runs as the hermes user on the host: the internet, the LAN
#     and the tailnet, including heartbeat's own LAN- and tailnet-bound
#     services such as PostgreSQL and Synapse. Heartbeat's loopback-only
#     services are not reachable. The host firewall cannot separate the sandbox
#     from the gateway: both run as the same UID, and the gateway needs the
#     tailnet for Strata and Synapse. `terminal.docker_network = false` is the
#     available lever if this changes.
#   - Isolated between conversations: containers persist across sessions
#     (upstream default), which is fine while the allow-lists name only
#     trusted users.
#   - Disk-limited: the per-container quota needs overlay2 on XFS with pquota
#     (here it's overlay on ZFS). Image storage lives in cacheDir on the
#     rolled-back root, so it is wiped at boot but has no cap within a boot.
#
# CPU and memory ARE limited, at the unit: rootless podman with cgroupfs and no
# user session cannot apply terminal.container_cpu/memory, but its pause
# process and every container land in this unit's cgroup (verified), so the
# systemd limits on hermes-gateway cover the gateway and all sandboxes together.
#
# Approvals: dangerous-command checks are NOT skipped here. Hermes only skips
# them for docker when the sandbox has no host bind mounts, and /output is
# one, so prompts go to the chat (approvals.mode = smart, upstream default).
# Sessions with nobody to answer (cron, single-query, unattended) inherit the
# upstream fail-closed default of `deny`. approvals.deny is the one rule set no
# mode, yolo or container bypasses; it carries upstream's pipe-to-shell
# examples (fnmatch globs over the whole command, where `|` is a literal pipe).
#
# Invariants hold between restarts only. The mount inventory, network mode and
# deny rules above all come from config.yaml, which the agent can write.
# Pinning them as managed keys means ExecStartPre restores them on the next
# start; it does not stop an in-session change. So ExecStartPre is the restore
# point, not the boundary. (Dropping terminal.docker_volumes would not
# re-enable the docker approval fast path either: persistent containers also
# bind-mount their per-task home and workspace from the host.)
#
# Image: hermes-sandbox:desktop is upstream's default and the only tag
# published. It carries the display stack the browser/computer-use tools need
# inside the sandbox; Hermes already passes --shm-size 1g for them. Point
# sandbox.image at a slimmer image if those tools are never wanted.
#
# Model: Strata on ixian via its Caddy endpoint. Strata's tvGuard stops it
# while the living-room TV is on, so expect 502/503 (with Retry-After) from
# the model during those windows — the gateway stays up and retries.
#
# Web search: web_search runs in the gateway process, so it reaches this host's
# loopback SearXNG; sandboxed terminal commands do not (pasta gives them a
# separate namespace). SearXNG is search-only, so web_extract resolves its own
# backend. Hermes' SearXNG client sends only `Accept: application/json`, which
# SearXNG's botdetection filters reject because Accept must contain text/html,
# so heartbeat runs SearXNG with the limiter off.
#
# Secrets: the sops `hermes/.env` file is read by systemd (PID 1) as the
# unit's EnvironmentFile and stays root-owned, and /run/secrets is
# inaccessible to the unit, so the agent cannot read any secret *file*. The
# values themselves are in the gateway's process environment by construction,
# so the agent process can see its own credentials; what keeps them out of the
# sandbox is Hermes' env filtering (terminal.docker_forward_env is empty).
# Expected keys: OPENAI_API_KEY (any non-empty value; Strata has no auth),
# MATRIX_HOMESERVER, MATRIX_USER_ID, MATRIX_ACCESS_TOKEN, MATRIX_DEVICE_ID,
# MATRIX_ALLOWED_USERS, DISCORD_BOT_TOKEN, DISCORD_ALLOWED_USERS,
# TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS.
#
# Backups: HERMES_HOME is restic-backed, so session transcripts, memories and
# Hermes' own ~/.hermes/.env (where `config set` mirrors TERMINAL_* keys, and
# where anything the agent stores lands) are part of the backup.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.hermes;

  hermesPkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hermes-agent;

  # Rootless podman runtime/storage for the hermes user. Image layers go to
  # the cache dir (re-pullable, kept out of the restic-backed dataset).
  runtimeDir = "/run/hermes";
  cacheDir = "/var/cache/hermes";

  # No systemd user session exists for a system user, so podman must manage
  # cgroups itself and log events to a file rather than the user journal.
  containersConf = pkgs.writeText "hermes-containers.conf" ''
    [engine]
    cgroup_manager = "cgroupfs"
    events_logger = "file"
  '';

  # Hermes' web tools run in the gateway process, not in the sandbox, so this
  # host's SearXNG is reachable; sandboxed terminal commands get their own
  # namespace through pasta and cannot reach loopback-only services. The empty
  # option resolves through the SearXNG module's clientUrl, which is loopback in
  # host mode and the WireGuard namespace address in VPN mode — a hardcoded
  # 127.0.0.1 would break as soon as SearXNG's VPN mode is on.
  searxngUrl =
    if cfg.web.searxngUrl != ""
    then cfg.web.searxngUrl
    else homelabCfg.services.searxng.clientUrl;

  hermesEnv =
    {
      HOME = cfg.dataDir;
      HERMES_HOME = cfg.dataDir;
      XDG_RUNTIME_DIR = runtimeDir;
      XDG_DATA_HOME = cacheDir;
      CONTAINERS_CONF = toString containersConf;
      HERMES_DOCKER_BINARY = "${pkgs.podman}/bin/podman";
    }
    // lib.optionalAttrs (cfg.web.searchBackend == "searxng" || cfg.web.searxngUrl != "") {
      # Only an instance URL, not a credential, so it stays in the unit rather
      # than in the sops .env. Hermes resolves it through its config-aware env
      # layer then process env, so the gateway, hermes-cli and cron all see it.
      # Emitted for an explicit URL even with no backend pinned, because
      # SEARXNG_URL is what the autodetect chain reads when no selection exists.
      SEARXNG_URL = searxngUrl;
    };

  # Managed keys are (re)applied on every start through Hermes' own
  # `config set`, so config.yaml stays writable for everything else Hermes
  # and its users change at runtime (skills, toolsets, migrations).
  #
  # A list, not an attrset, because order matters: `config set model.provider`
  # can drop a leftover model.base_url belonging to another provider, so the
  # provider must be set before the endpoint (an attrset would apply keys
  # alphabetically, base_url first).
  managedConfig = [
    {
      key = "model.provider";
      value = "custom";
    }
    {
      key = "model.base_url";
      value = cfg.model.baseUrl;
    }
    {
      key = "model.default";
      value = cfg.model.name;
    }
    {
      key = "terminal.backend";
      value = "docker";
    }
    {
      key = "terminal.docker_image";
      value = cfg.sandbox.image;
    }
    {
      # Already the upstream default; pinned so no gateway credential can be
      # forwarded into the sandbox by a runtime config change surviving restart.
      key = "terminal.docker_forward_env";
      value = builtins.toJSON [];
    }
    {
      # Host-visible export dir: MEDIA delivery runs in the gateway process,
      # so files the agent writes to /output in the sandbox must be readable
      # here. It has to stay writable from the container.
      key = "terminal.docker_volumes";
      value = builtins.toJSON ["${outputDir}:/output"];
    }
    {
      # Both feed the mount/network inventory in the header: extra args could
      # add --network=host or -v /:/host, and mounting the host cwd would
      # expose all of HERMES_HOME (the cwd defaults to dataDir).
      key = "terminal.docker_extra_args";
      value = builtins.toJSON [];
    }
    {
      key = "terminal.docker_mount_cwd_to_workspace";
      value = "false";
    }
    {
      # Upstream default, pinned so the approval layer is a managed key.
      key = "approvals.mode";
      value = "smart";
    }
    {
      # Never-bypassable deny rules (see the Approvals note in the header).
      key = "approvals.deny";
      value = builtins.toJSON [
        "*curl*|*sh*"
        "*wget*|*sh*"
      ];
    }
    {
      # A per-capability key, so it wins over whatever `hermes tools` stored as
      # the shared web selection and does not reroute web_extract. Written even
      # when empty: writing it only for a non-empty value would leave a stale
      # `searxng` in config.yaml after the option is cleared, and Hermes would
      # then fail every search with "SEARXNG_URL is not set" instead of falling
      # back to its autodetected backend. An empty value reads as unset, so
      # clearing the option resets the runtime selection too.
      key = "web.search_backend";
      value = cfg.web.searchBackend;
    }
  ];

  outputDir = "${cfg.dataDir}/cache/documents";

  applyConfig = pkgs.writeShellScript "hermes-apply-config" (
    lib.concatStringsSep "\n" (
      ["${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg outputDir}"]
      ++ map ({
        key,
        value,
      }: "${hermesPkg}/bin/hermes config set ${lib.escapeShellArg key} ${lib.escapeShellArg value} >/dev/null")
      managedConfig
    )
  );

  # `hermes-cli` — run Hermes from an SSH session on this host against the
  # same HERMES_HOME (config, memories, sessions, SQLite state) the gateway
  # uses; SQLite runs in WAL mode, so both can use it at once. It does NOT get
  # the gateway's EnvironmentFile, so it has no Matrix/Discord/Telegram
  # credentials. Strata needs no auth, so it gets a fixed, non-secret
  # OPENAI_API_KEY placeholder to satisfy Hermes' non-empty-key check; change
  # this if model.baseUrl ever points at an endpoint that needs a real key.
  # The gateway must be running, since it owns runtimeDir. Sandboxes started
  # from the CLI are not verified to fall under the gateway unit's CPU/memory
  # limits; they are likely spawned in the SSH session's cgroup instead.
  hermesCli = pkgs.writeShellScriptBin "hermes-cli" ''
    exec /run/wrappers/bin/sudo -u hermes ${pkgs.coreutils}/bin/env -C ${lib.escapeShellArg cfg.dataDir} \
      ${lib.concatStringsSep " " (lib.mapAttrsToList (n: v: "${n}=${lib.escapeShellArg v}") hermesEnv)} \
      OPENAI_API_KEY=unused \
      PATH=/run/wrappers/bin:${lib.makeBinPath [pkgs.podman pkgs.coreutils]} \
      ${hermesPkg}/bin/hermes "$@"
  '';

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "hermes";
    inherit (cfg) dataDir;
    user = "hermes";
    group = "hermes";
    mainServices = ["hermes-gateway"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-hermes";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        # The default URL is this host's loopback instance, so naming SearXNG
        # only makes sense when the service is enabled here or when an instance
        # elsewhere is named explicitly.
        assertion = cfg.web.searchBackend != "searxng" || homelabCfg.services.searxng.enable || cfg.web.searxngUrl != "";
        message = "homelab.services.hermes.web: searchBackend = \"searxng\" resolves to this host's loopback SearXNG; enable homelab.services.searxng or set web.searxngUrl to an instance elsewhere.";
      }
    ];

    # Rootless podman needs /etc/containers (policy.json, registries.conf),
    # not the rootful homelab.services.podman module, so don't depend on it.
    virtualisation = {
      containers = {
        enable = true;
      };
    };

    homelab = {
      zfs = {
        datasets = {
          hermes = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = cfg.dataDir;
            requiredBy = ["hermes-gateway.service"];

            restic = {
              enable = cfg.zfs.restic.enable;
            };
          };
        };
      };
    };

    users = {
      users = {
        hermes = {
          isSystemUser = true;
          group = "hermes";
          uid = cfg.userId;
          home = cfg.dataDir;
          # Subordinate IDs for the rootless podman user namespace.
          subUidRanges = [
            {
              startUid = cfg.sandbox.subIdStart;
              count = 65536;
            }
          ];
          subGidRanges = [
            {
              startGid = cfg.sandbox.subIdStart;
              count = 65536;
            }
          ];
        };
      };

      groups = {
        hermes = {
          gid = cfg.groupId;
        };
      };
    };

    environment = lib.mkMerge [
      {
        systemPackages = [hermesCli];
      }
      (persistenceHelpers.mkPersistenceDirs {
        inherit homelabCfg;
        zfsEnable = cfg.zfs.enable;
        directories = [cfg.dataDir];
      })
    ];

    systemd = lib.mkMerge [
      permSvc.systemd
      {
        services = {
          hermes-gateway = {
            description = "Hermes Agent messaging gateway";
            wantedBy = ["multi-user.target"];
            after = ["network-online.target"];
            wants = ["network-online.target"];

            environment = hermesEnv;

            # newuidmap/newgidmap are setuid wrappers; podman finds them on PATH.
            path = [
              "/run/wrappers"
              pkgs.podman
              pkgs.coreutils
            ];

            serviceConfig = {
              User = "hermes";
              Group = "hermes";
              EnvironmentFile = config.sops.secrets."hermes/.env".path;
              WorkingDirectory = cfg.dataDir;
              ExecStartPre = applyConfig;
              ExecStart = "${hermesPkg}/bin/hermes gateway run --replace --external-supervisor";
              Restart = "on-failure";
              RestartSec = "10s";
              # Hermes drains in-flight agent turns and cron jobs on stop and
              # warns unless systemd allows >= 70s before SIGKILL.
              TimeoutStopSec = "90s";

              RuntimeDirectory = "hermes";
              RuntimeDirectoryMode = "0700";
              CacheDirectory = "hermes";
              CacheDirectoryMode = "0700";

              # CPU/memory limits for the gateway plus every sandbox container
              # (all in this cgroup; see the header). Verified on heartbeat: a
              # 5 GB allocation in the sandbox peaked at exactly 4096 MiB RAM +
              # 1024 MiB swap and was OOM-killed (exit 137), nothing else was.
              #   - No MemoryHigh: without much swap it throttles a runaway
              #     process indefinitely instead of letting it hit MemoryMax.
              #   - MemorySwapMax: heartbeat has ~63 GB of zram swap, which
              #     would otherwise absorb anything past MemoryMax.
              #   - OOMPolicy = continue: the default (stop) takes the whole
              #     gateway down whenever one sandbox command is OOM-killed.
              #   - TasksMax: Hermes' --pids-limit 2048 fork-bomb guard is inert
              #     without delegated cgroups, so it is enforced here instead.
              #     Verified: a fork loop stopped at 2028 children (EAGAIN) with
              #     the unit's pids.peak at 2048.
              CPUQuota = "200%";
              MemoryMax = "4G";
              MemorySwapMax = "1G";
              OOMPolicy = "continue";
              TasksMax = 2048;

              # Hardening, limited to what rootless podman tolerates. The
              # podman pause process lives in this unit's cgroup and mount
              # namespace, so every container inherits these settings.
              #
              # Tested on heartbeat (systemd 260, podman 5.8) and broke the
              # sandbox, so left off:
              #   RestrictSUIDSGID       — image unpack fails on setuid files
              #                            ("open /usr/bin/chage: operation
              #                            not permitted")
              #   ProtectKernelTunables  — overmounts /proc/{sys,kcore,...}; the
              #                            kernel then refuses a fresh procfs
              #                            in the container's pid namespace
              #   ProtectHostname        — same crun "mount proc" failure
              # Left off on reasoning, not tested:
              #   NoNewPrivileges        — would block the setuid
              #                            newuidmap/newgidmap wrappers
              #   PrivateUsers, RestrictNamespaces — podman needs fresh userns
              #   PrivateDevices, ProtectClock — replace the device list with
              #                            one that lacks /dev/net/tun and
              #                            /dev/fuse (DeviceAllow below grants
              #                            exactly those instead)
              # Everything set below passed the same test run together (rootless
              # container start, /output write, egress, DNS, and PTYs: both
              # `podman exec -t` and openpty() inside the container work
              # without adding char-pts to DeviceAllow).
              ProtectSystem = "strict";
              ProtectHome = true;
              ReadWritePaths = [cfg.dataDir];
              PrivateTmp = true;
              ProtectKernelModules = true;
              ProtectControlGroups = true;
              LockPersonality = true;
              DeviceAllow = [
                "/dev/fuse rwm"
                "/dev/net/tun rwm"
              ];
              RestrictAddressFamilies = [
                "AF_UNIX"
                "AF_INET"
                "AF_INET6"
                "AF_NETLINK"
              ];
              # PID 1 reads EnvironmentFile before this applies, so no secret
              # *file* is readable from the unit (the values are still in the
              # gateway's environment; see the header).
              InaccessiblePaths = ["-/run/secrets" "-/run/secrets.d"];
            };
          };
        };
      }
    ];
  };
}
