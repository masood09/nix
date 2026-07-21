# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-machine homelab infrastructure using Nix Flakes. Manages 7 NixOS servers, 2 NixOS desktops, and 1 macOS machine with home-manager, sops-nix secrets, ZFS, and impermanence.

## Commands

```bash
just deploy                          # Deploy to current machine (runs preflight first)
just machine=heartbeat deploy        # Build and deploy on remote machine via SSH
just preflight                       # Check formatting + lint (no auto-fix)
just test                            # Full validation: every host eval, sops, lock drift
just up                              # Update flake.lock
just lint                            # Check with statix
just fmt                             # Format with alejandra
just gc                              # Garbage collect (default: 7d retention)
just gc age=30d                      # Garbage collect with custom retention
                                     # (automatic GC also runs Sun 06:00 with 14d retention — see modules/nixos/_gc.nix)
just repair                          # Verify and repair nix store
just build-iso                       # Build NixOS installer ISO
just sops-rotate                     # Rotate all sops keys (requires clean git)
just sops-update                     # Update sops key files (interactive)
```

## Deployment

After making config changes, stop at preflight (`just preflight`, or `nix fmt -- --check .` + `statix check .`). Do not run `just deploy`, `darwin-rebuild switch`, or `nixos-rebuild switch` — the user runs activation themselves so they can watch the output and decide when to apply. Only run a deploy command if the user explicitly asks.

## Architecture

### Flake Structure
- `flake.nix` - Entry point defining all NixOS and Darwin configurations (`mkNixOSConfig` for servers, `mkNixOSDesktopConfig` for desktops, `mkDarwinConfig` for macOS)
- `machines/` - Per-machine configs (each has `default.nix`, `hardware-configuration.nix`, and — on every machine except `work-okta` and `nixiso` — `_config.nix`, `_networking.nix`, `_secrets.nix`, `secrets.sops.yaml`, `install.org`, and often a `disko/` directory)
- `modules/` - Reusable modules split by concern:
  - `modules/home-manager/` - User environment (programs as `_<name>.nix` files in `programs/`)
  - `modules/nixos/` - NixOS system config (boot, networking, users, impermanence, zfs)
  - `modules/macos/` - nix-darwin system config
  - `modules/shared/` - Cross-platform option schemas imported by both NixOS and Darwin (role, purpose, primaryUser, networking)
  - `modules/services/` - 28 declarative services (each in own directory)
- `lib/` - Shared helper libraries:
  - `persistence-helpers.nix` - Impermanence bind-mount guard (three-part condition: `impermanence && !isRootZFS && !zfsEnable`)
  - `systemd-helpers.nix` - Permission-fixing oneshot service generator (`mkPermissionService`)
  - `zfs-options.nix` - ZFS dataset option builder
- `nix/pkgs/` - Custom package definitions (auto-discovered)
- `nix/overlays/` - Package overlays
- `nix/services/` - Custom NixOS service modules (nightscout, mailarchiver, matrix-authentication-service)
- `secrets/` - Shared sops-encrypted secrets
- `docs/` - Documentation:
  - `service-registry.org` - Authoritative source for UIDs, GIDs, and port assignments
  - `architecture.org` - System architecture overview
  - `backup.org` - Backup strategy and procedures
  - `firmware.org` - Firmware update policy (fwupd is desktop-only) and the server procedure
  - `secrets-rotation.org` - Secrets rotation runbook
  - `inventory.org` - Packages, services, and fonts per machine
  - `desktop.org` - Desktop architecture (login, graphics, theming)
  - `zen.org` - Zen Browser configuration notes

### Custom Options Namespace

All configuration uses `homelab.*` options defined in the modules. The cross-platform identity schema lives in `modules/shared/options.nix`; platform-specific behavior lives in the NixOS and Darwin module trees.

```nix
homelab = {
  role = "server";  # or "desktop"
  purpose = "Main NAS";
  primaryUser = { userName = "masoodahmed"; userId = 1000; };
  networking = { hostName = "heartbeat"; domain = "mantannest.com"; };
  desktop = { enable = true; niri = { enable = true; }; shell = "none"; };
  stylix = { enable = true; wallpaper = ../../nix/wallpapers/cosy-retreat-sunset.png; };
  programs.emacs.enable = true;
  services.immich.enable = true;
};
```

### Theming (Stylix)
- Single source of truth at system level: `modules/nixos/_stylix.nix` (NixOS), `modules/macos/_stylix.nix` (Darwin)
- All settings (`homelab.stylix.*`) propagate to Home-Manager via Stylix's `autoImport` + `followSystem`
- HM-only target overrides (starship, waybar, zen-browser) are injected via `home-manager.sharedModules` in the system module
- Stylix is enabled by default on all machines; set `homelab.stylix.enable = false` only for an explicit opt-out
- **Server closure hygiene**: Servers disable GTK, Qt, KDE, and GNOME Stylix targets (NixOS + HM), cursor theming, NixOS XDG sound/icon/mime assets, and HM `xdg.mime`. Without these gates the server closure pulls ~1 GB of Qt/GTK/Wayland/theme packages. The gates live in `_stylix.nix` (NixOS + HM targets, XDG) and `home.nix` (HM `xdg.mime`)
- Darwin Stylix does not support `stylix.cursor` (no cursor module in `darwinModules`)

### File Naming Convention
- `_` prefix for private/internal config files (e.g., `_config.nix`, `_networking.nix`)
- `default.nix` as main entry point for directories

### Code Style
- **Nested attribute sets**: Always use fully nested structure, never dot notation for attribute sets
  - Good: `services = { greetd = { enable = true; }; };`
  - Bad: `services.greetd = { enable = true; };`
  - This applies to all top-level options: `services`, `programs`, `security`, `environment`, etc.
  - It also applies to third-party settings DSLs and to paths with interpolated keys. Write `action = { close-window = {}; };` not `action.close-window = {};`, and `certs = { ${domain} = {...}; };` not `certs.${domain} = {...};`.
  - **Sole exemption**: disko disk layout (`modules/nixos/disko/`, `machines/*/disko/`) keeps `disk.root` / `zpool.rpool` to match upstream disko idiom. Everywhere else the rule holds with no exceptions.
- **Cross-platform HM modules**: If a shared Home Manager module writes to an option namespace provided only on one platform (or only on desktops), guard the `config` block with `lib.optionalAttrs (options.<path> ? <name>)`. Do **not** use `lib.mkIf` for this — `mkIf` still registers a conditional definition with the module system, which triggers "option does not exist" when the namespace is entirely absent. `optionalAttrs` evaluates at the Nix language level and returns `{}`, so no definition is registered at all. Do not try to make `imports` depend on `pkgs`/`config` to avoid missing-option errors; that causes module recursion. See `modules/home-manager/programs/zen/` for the canonical example.
- **Linux-only HM behavior**: Even when an option namespace exists on both platforms, gate writes that are only meaningful on Linux (e.g. `dconf`, `xdg.configFile."fontconfig/..."`, `bubblewrap` package, dbus-dependent activation) behind `lib.mkIf pkgs.stdenv.isLinux`. macOS uses Core Text / Keychain / `sandbox-exec` instead, so the same options either no-op silently or accumulate dead config in `~/.config/`.

### Persistence Model
- ZFS machines: ephemeral root via ZFS rollback to blank snapshot, persistent data in `/nix/persist`
- Non-ZFS machines (usul, caretaker, sonic): tmpfs root wiped on reboot, LUKS-encrypted ext4 at `/nix`, persistent data in `/nix/persist`
- Services that manage their own ZFS dataset bypass impermanence bind-mounts entirely
- The three-part guard in `lib/persistence-helpers.nix` handles all scenarios: `impermanence && !isRootZFS && !zfsEnable`
- Import the helper as: `persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};`

### Secrets Management
- sops-nix with age encryption
- Per-machine keys defined in `.sops.yaml`
- Shared secrets: `secrets/secrets.sops.yaml`
- Machine-specific: `machines/{name}/secrets.sops.yaml`
- Reference in config: `config.sops.secrets."path/to/secret".path`
- macOS key location: `~/.config/sops/age/keys.txt`

### NixOS Servers
- ZFS root filesystem with encryption (or LUKS+ext4 for non-ZFS machines)
- Impermanence: ephemeral root, persistent data in `/nix/persist`
- Immutable users (mutableUsers = false, passwords via sops)
- disko for declarative disk management

### Darwin / Homebrew Policy

Long-term direction on `work-okta` (the sole macOS machine) is to phase out Homebrew casks and `masApps` in favor of nixpkgs / Home Manager. Homebrew is a fallback for packages that don't yet build cleanly on Darwin via nixpkgs, not a permanent choice. On `work-okta` the corporate Artifactory proxy blocks all third-party taps, so shared taps/brews/casks are force-cleared in `machines/work-okta/_packages.nix`.

- For new Darwin packages, default to nixpkgs/HM. Only fall back to Homebrew when there's a concrete blocker.
- When falling back to a cask, leave a `TECH DEBT:` comment near the cask entry explaining what's blocking the nixpkgs route, and re-evaluate periodically.
- When a Darwin build breaks and the easy fix is "just use the cask," frame it as tech debt rather than the preferred solution.

### Service Registry
Before adding services, check `docs/service-registry.org` for:
- Service user UIDs (start at 3000)
- Port allocations (avoid collisions)
- Group IDs (match UIDs)

### Adding a New Service
- Custom services (no upstream NixOS module) must set `isSystemUser = true` and `group` on their user definitions
- Services backed by upstream NixOS modules (e.g., immich, vaultwarden) do not need manual user config as the upstream module handles it
- Use `lib/persistence-helpers.nix` for impermanence bind-mounts
- Use `lib/systemd-helpers.nix` for permission-fixing oneshot services
- Use `lib/zfs-options.nix` for ZFS dataset options

## Research & Tool Routing

When the user describes a problem, pick the right tool yourself — they shouldn't have to name it. Rough routing for Nix work in this repo:

- **Option schema / type / default / which channel** → `mcp__nixos__*` (`darwin_search`, `home_manager_options_by_prefix`, `nixos_info`, etc.). Authoritative for the channels pinned in this flake.
- **Package version availability / nixpkgs commit lookup** → `mcp__nixos__nixhub_package_versions` / `nixhub_find_version`.
- **Idiomatic example, manual prose, third-party flake usage patterns** → `context7` (`resolve-library-id` then `get-library-docs` with a `topic` filter — never call `get-library-docs` without a topic).
- **Anything in this repo** → `Read` / `Grep` / `Glob`, no MCP.
- **Fast-moving flake inputs** (niri, noctalia, mcp-servers-nix, claude-code, codex-cli-nix, zen-browser, betterfox) → `WebFetch` the upstream repo, since context7's cache may lag the flake input.

Combine sources when useful: nixos MCP for the exact option name, then context7 for an example of how to use it. Don't narrate routing decisions unless they matter.

## Key Dependencies

- nixpkgs: `nixos-26.05`
- nixpkgs-unstable: `nixos-unstable` (used by noctalia and to source the latest `opencode` package)
- home-manager: `release-26.05`
- nix-darwin: `nix-darwin-26.05`
- stylix: `release-26.05`
- niri: `epireyn/niri-flake` (fork of `sodiboo/niri-flake`; declarative Niri compositor config + Stylix integration. Included in `mkNixOSDesktopConfig`, not `mkNixOSConfig`, to avoid pulling niri into server closures. No nixpkgs `follows` — it must build against the fork's own nixpkgs to hit `niri-epireyn.cachix.org`, which covers 26.05)
- noctalia: `noctalia-dev/noctalia`, `cachix` branch (desktop shell, v5. HM module included in `mkNixOSDesktopConfig` via `home-manager.sharedModules`, not in shared `home.nix`, because the flake wrapper unconditionally pulls the shell package into every closure. No nixpkgs `follows` so builds resolve from `noctalia.cachix.org`; v4 lives on the `legacy-v4` branch)
- mcp-servers-nix: `natsukium/mcp-servers-nix` (declarative MCP server registry; HM bridge module reads `mcp-servers.programs.<name>.enable` and writes the resulting entries into `programs.mcp.servers`, which `_claude-code.nix`/`_codex-cli.nix`/`_opencode.nix` consume; imported in shared `home.nix` but the registry itself is gated on `homelab.programs.ai_tools` inside `modules/home-manager/programs/_mcp.nix` so server closures stay free of MCP packages)
- zen-browser: `0xc000022070/zen-browser-flake` (Zen Browser HM module; included in `desktopNixOSModules` via `home-manager.sharedModules` for NixOS desktops and in `mkDarwinConfig` for macOS, not in shared `home.nix`, because the flake wrapper unconditionally pulls heavyweight browser/Qt packages into every closure even when the program is never enabled)
- claude-code (`sadjow/claude-code-nix`) and codex-cli-nix (`sadjow/codex-cli-nix`): both auto-update hourly and ship their own binary caches. No nixpkgs `follows`, and they are consumed via `inputs.<name>.packages.<system>.default` — **not** their overlays, which would rebuild against our nixpkgs and miss the cache on every `just up`
- headplane: pinned to `v0.6.2`; nixos-26.05's native `services.headplane` module is `disabledModules`-ed in `flake.nix` so only the flake module declares the option
- authentik-nix: deliberately no nixpkgs `follows` (upstream doesn't support it; overriding causes a cache miss that OOMs the aarch64 SSO box)
- Other inputs: disko, impermanence, sops-nix, nix-homebrew, nix-minecraft, betterfox

**Binary-cache rule of thumb**: an input that publishes its own cachix cache must *not* get `inputs.nixpkgs.follows`, and must be consumed via its own `packages` attr rather than an overlay. Substituters and public keys live in `modules/nixos/default.nix`.

## Machines

**NixOS servers**: accesscontrolsystem, commrelay, meshcontrol, watchfulsystem, caretaker, heartbeat, trialunit
**NixOS desktops**: usul (primary laptop), sonic (laptop)
**macOS**: work-okta
**Other**: nixiso (minimal NixOS installer ISO)
