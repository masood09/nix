# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-machine homelab infrastructure using Nix Flakes. Manages 7 NixOS servers, 3 NixOS desktops, and 2 macOS machines with home-manager, sops-nix secrets, ZFS, and impermanence.

## Commands

```bash
just deploy                          # Deploy to current machine (runs preflight first)
just deploy machine=heartbeat        # Build and deploy on remote machine via SSH
just preflight                       # Check formatting + lint (no auto-fix)
just up                              # Update flake.lock
just lint                            # Check with statix
just fmt                             # Format with alejandra
just gc                              # Garbage collect (default: 7d retention)
just gc age=30d                      # Garbage collect with custom retention
just repair                          # Verify and repair nix store
just build-iso                       # Build NixOS installer ISO
just sops-rotate                     # Rotate all sops keys (requires clean git)
just sops-update                     # Update sops key files (interactive)
```

## Architecture

### Flake Structure
- `flake.nix` - Entry point defining all NixOS and Darwin configurations
- `machines/` - Per-machine configs (each has `default.nix`, `_config.nix`, `hardware-configuration.nix`)
- `modules/` - Reusable modules split by concern:
  - `modules/home-manager/` - User environment (programs as `_<name>.nix` files in `programs/`)
  - `modules/nixos/` - NixOS system config (boot, networking, users, impermanence, zfs)
  - `modules/macos/` - nix-darwin system config
  - `modules/shared/` - Cross-platform option schemas imported by both NixOS and Darwin (role, purpose, primaryUser, networking)
  - `modules/services/` - 27 declarative services (each in own directory)
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
  - `secrets-rotation.org` - Secrets rotation runbook
  - `inventory.org` - Packages, services, and fonts per machine
  - `desktop.org` - Desktop architecture (login, graphics, theming)
  - `analysis.org` - Codebase review findings and recommendations
  - `openai-analyze.org` - Current Codex analysis and follow-up findings
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
- Darwin Stylix does not support `stylix.cursor` (no cursor module in `darwinModules`)

### File Naming Convention
- `_` prefix for private/internal config files (e.g., `_config.nix`, `_networking.nix`)
- `default.nix` as main entry point for directories

### Code Style
- **Nested attribute sets**: Always use fully nested structure, never dot notation for attribute sets
  - Good: `services = { greetd = { enable = true; }; };`
  - Bad: `services.greetd = { enable = true; };`
  - This applies to all top-level options: `services`, `programs`, `security`, `environment`, etc.
- **Cross-platform HM modules**: If a shared Home Manager module writes to an option namespace provided only on one platform, guard the subtree with `options.<path> ? <name>` or `lib.optionalAttrs`. Do not try to make `imports` depend on `pkgs`/`config` to avoid missing-option errors; that causes module recursion.

### Persistence Model
- ZFS machines: ephemeral root via ZFS rollback to blank snapshot, persistent data in `/nix/persist`
- Non-ZFS machines (arrakis, caretaker): tmpfs root wiped on reboot, LUKS-encrypted ext4 at `/nix`, persistent data in `/nix/persist`
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

## Key Dependencies

- nixpkgs: `nixos-25.11`
- nixpkgs-unstable: `nixos-unstable` (used by noctalia)
- home-manager: `release-25.11`
- nix-darwin: `nix-darwin-25.11`
- stylix: `release-25.11`
- niri: `sodiboo/niri-flake` (declarative Niri compositor config + Stylix integration; NixOS module imported per desktop machine, not in `mkNixOSConfig`, to avoid pulling niri into server closures)
- Other inputs: disko, impermanence, sops-nix, nix-homebrew, authentik-nix, headplane, claude-code, codex-cli-nix, zen-browser, betterfox, noctalia

## Machines

**NixOS servers**: accesscontrolsystem, commrelay, meshcontrol, watchfulsystem, caretaker, heartbeat, trialunit
**NixOS desktops**: arrakis (primary laptop), commandmodule (laptop), sonic (laptop)
**macOS**: murderbot, work-pantheon
**Other**: nixiso (minimal NixOS installer ISO)
