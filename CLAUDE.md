# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-machine homelab infrastructure using Nix Flakes. Manages 7 NixOS servers, 2 NixOS desktops, and 2 macOS machines with home-manager, sops-nix secrets, ZFS, and impermanence.

## Commands

```bash
just deploy                          # Deploy to current machine (runs preflight first)
just deploy machine=heartbeat        # Deploy to specific machine
just deploy machine=heartbeat ip=x   # Deploy remotely via SSH
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
  - `analysis.org` - Codebase review findings and recommendations
  - `zen.org` - Zen Browser configuration notes

### Custom Options Namespace

All configuration uses `homelab.*` options defined in the modules:

```nix
homelab = {
  role = "server";  # or "desktop"
  purpose = "Main NAS";
  primaryUser = { userName = "masoodahmed"; userId = 1000; };
  networking = { hostName = "heartbeat"; domain = "mantannest.com"; };
  programs.emacs.enable = true;
  services.immich.enable = true;
};
```

### File Naming Convention
- `_` prefix for private/internal config files (e.g., `_config.nix`, `_networking.nix`)
- `default.nix` as main entry point for directories

### Code Style
- **Nested attribute sets**: Always use fully nested structure, never dot notation for attribute sets
  - Good: `services = { greetd = { enable = true; }; };`
  - Bad: `services.greetd = { enable = true; };`
  - This applies to all top-level options: `services`, `programs`, `security`, `environment`, etc.

### Persistence Model
- Servers use ZFS root with impermanence: ephemeral root wipes on boot, persistent data in `/nix/persist`
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
- ZFS root filesystem with encryption
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
- home-manager: `release-25.11`
- nix-darwin: `nix-darwin-25.11`
- stylix: `release-25.11`
- Other inputs: disko, impermanence, sops-nix, nix-homebrew, authentik-nix, headplane, claude-code, zen-browser, betterfox, sysc-greet

## Machines

**NixOS servers**: accesscontrolsystem, commrelay, meshcontrol, watchfulsystem, caretaker, heartbeat, trialunit
**NixOS desktops**: commandmodule (primary dev, laptop), sonic (desktop)
**macOS**: murderbot, work-pantheon
**Other**: nixiso (minimal NixOS installer ISO)
