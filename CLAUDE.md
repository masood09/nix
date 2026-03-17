# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-machine homelab infrastructure using Nix Flakes. Manages 7 NixOS servers, 1 NixOS desktop/laptop, and 2 macOS machines with home-manager, sops-nix secrets, ZFS, and impermanence.

## Commands

```bash
just deploy                          # Deploy to current machine
just deploy machine=heartbeat        # Deploy to specific machine
just deploy machine=heartbeat ip=x   # Deploy remotely via SSH
just up                              # Update flake.lock
just lint                            # Check with statix
just fmt                             # Format with alejandra (or: nix fmt)
just gc                              # Garbage collect
just repair                          # Verify and repair nix store
just build-iso                       # Build NixOS installer ISO
just sops-rotate                     # Rotate all sops keys
just sops-update                     # Update sops key files
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
- `nix/pkgs/` - Custom package definitions (auto-discovered)
- `nix/overlays/` - Package overlays
- `nix/services/` - Custom NixOS service modules
- `secrets/` - Shared sops-encrypted secrets
- `docs/service-registry.org` - Authoritative source for UIDs, GIDs, and port assignments

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

## Key Dependencies

- nixpkgs: `nixos-25.11`
- home-manager: `release-25.11`
- nix-darwin: `nix-darwin-25.11`
- Other inputs: disko, impermanence, sops-nix, nix-homebrew, authentik-nix, catppuccin, headplane

## Machines

**NixOS servers**: accesscontrolsystem, commrelay, meshcontrol, watchfulsystem, caretaker, heartbeat, trialunit
**NixOS desktop**: commandmodule (laptop)
**macOS**: murderbot (primary dev), work-pantheon
