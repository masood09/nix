# AGENTS.md

This repository is a multi-machine Nix Flake for a homelab: NixOS servers, NixOS desktops, and macOS machines managed with `home-manager`, `nix-darwin`, `disko`, `sops-nix`, ZFS, and impermanence.

Use this file as the fast-start guide for coding agents working in `/home/masoodahmed/code/nix`.

## Scope And Layout

- Entry point: `flake.nix`
- Machine definitions: `machines/<name>/`
- Shared NixOS modules: `modules/nixos/`
- Shared Home Manager modules: `modules/home-manager/`
- Shared Darwin modules: `modules/macos/`
- Service modules: `modules/services/`
- Custom NixOS service modules: `nix/services/`
- Custom packages: `nix/pkgs/`
- Shared helpers: `lib/`
- Operational docs: `docs/`
- Secrets: `secrets/` and `machines/*/*.sops.yaml`

## Agent Priorities

- Prefer minimal, local changes that match existing patterns.
- Do not invent a new module structure if an adjacent module already shows the right pattern.
- Preserve cross-platform behavior: NixOS and Darwin share some option schemas but not all implementations.
- Never hardcode secrets; use `sops-nix` secret paths.
- Before adding a new service, check `docs/service-registry.org` for UID/GID and port allocations.

## Build, Lint, And Validation Commands

Primary commands live in `justfile`.

- List available tasks: `just`
- Format repo: `just fmt`
- Check formatting only: `nix fmt -- --check .`
- Lint repo: `just lint`
- Direct linter invocation: `statix check .`
- Run standard local validation: `just preflight`
- Update flake inputs: `just up`
- Build installer ISO: `just build-iso`
- Deploy current machine: `just deploy`
- Deploy a remote NixOS host: `just machine=heartbeat deploy`

## Test Strategy

There is no conventional unit-test suite in this repo. Validation is mostly Nix evaluation, targeted builds, and deployment-safe checks.

- Full fast validation script: `./test-flake.sh`
- Flake metadata: `nix flake metadata`
- Show flake outputs: `nix flake show`
- Parse one file for syntax: `nix-instantiate --parse path/to/file.nix`

## Running A Single Test

Because this repo is configuration-heavy, a “single test” usually means evaluating or building one host, one output, or one file.

- Evaluate one NixOS host: `nix eval .#nixosConfigurations.heartbeat.config.system.name`
- Build one NixOS host: `nix build .#nixosConfigurations.heartbeat.config.system.build.toplevel`
- Evaluate one Darwin host: `nix eval .#darwinConfigurations.murderbot.system.primaryUser`
- Build one Darwin host: `nix build .#darwinConfigurations.murderbot.system`
- Build one custom package: `nix build .#mailarchiver`
- Check one Nix expression parses: `nix-instantiate --parse modules/services/mailarchiver/default.nix`

When changing only one machine or service, prefer the narrowest command that exercises that change first.

## Recommended Validation By Change Type

- Nix formatting/style only: `nix fmt -- --check . && statix check .`
- Shared module change: `just preflight` plus at least one affected host eval/build
- Machine-only change: evaluate or build only that machine
- Service module change: evaluate/build a machine that enables that service
- Flake wiring change: run `./test-flake.sh`
- Installer change: `just build-iso`

## Important Machines

NixOS hosts currently include:

- `accesscontrolsystem`
- `arrakis`
- `caretaker`
- `commandmodule`
- `commrelay`
- `heartbeat`
- `meshcontrol`
- `nixiso`
- `sonic`
- `trialunit`
- `watchfulsystem`

Darwin hosts currently include:

- `murderbot`
- `work-pantheon`

## Formatting Rules

- Formatting is handled by `alejandra` via `nix fmt`.
- Linting is handled by `statix`.
- Do not hand-format in a way that fights the formatter.
- Keep files ASCII unless the file already uses Unicode and there is a good reason.

## Nix Style Guidelines

- Use fully nested attribute sets, not dotted attribute assignment for nested config.
- Preferred:

```nix
services = {
  greetd = {
    enable = true;
  };
};
```

- Avoid:

```nix
services.greetd = {
  enable = true;
};
```

- Keep attribute trees visually shallow and grouped by subsystem.
- Use one attribute per line for lists unless the list is tiny and already formatted that way.
- Favor `inherit (...) foo bar;` when it reduces repetition and keeps ownership clear.

## Imports And File Organization

- Use `default.nix` as the entry point for directories.
- Files prefixed with `_` are private/internal helpers, such as `_config.nix` or `_networking.nix`.
- In machine `default.nix` files, keep local machine imports together, then shared module directories.
- In module directories, import submodules unconditionally and gate behavior inside each module.
- Do not make `imports` depend on `config` or `pkgs`; that can trigger module recursion.

## Module Patterns

- Typical argument set order is `{ config, lib, pkgs, ... }:` or a small variant.
- Use `let` bindings for `cfg = ...`, `homelabCfg = config.homelab`, and other repeated expressions.
- Define options with `lib.mkOption` and `lib.mkEnableOption`.
- Use explicit Nix types: `lib.types.str`, `lib.types.int`, `lib.types.port`, `lib.types.enum`, `lib.types.nullOr`, `lib.types.listOf`, `lib.types.attrsOf`.
- Use `lib.mkIf` to gate optional config.
- Use `lib.mkMerge`, `lib.optionalAttrs`, and `lib.optionals` to compose conditional pieces.
- For cross-platform Home Manager modules, guard platform-specific namespaces with `options.<path> ? <name>` or `lib.optionalAttrs`.

## Naming Conventions

- Repository option namespace: `homelab.*`
- Shared machine identity lives under `homelab.role`, `homelab.purpose`, `homelab.primaryUser`, and `homelab.networking`.
- Local module variables usually use `cfg` for the module config and `homelabCfg` for top-level repo config.
- Service modules typically live in `modules/services/<service>/` with `default.nix` plus `options.nix` and supporting files.
- Custom packages live in `nix/pkgs/<name>/default.nix` and are auto-discovered.

## Types, Defaults, And Option Design

- Prefer declarative options over ad hoc literals in machine configs.
- Add sane defaults where they are truly global; otherwise require explicit values.
- Use enums instead of free-form strings when the valid values are known.
- Keep shared schema in `modules/shared/options.nix`; keep platform-specific implementation in `modules/nixos/` or `modules/macos/`.

## Error Handling And Safety

- Prefer `assertions` with clear messages for invalid configuration combinations.
- Gate dependent services explicitly, for example requiring PostgreSQL or MongoDB when needed.
- Use `lib.mkIf` rather than partial config that silently misconfigures a service.
- For services not backed by upstream NixOS modules, set `isSystemUser = true;` and `group = "<name>";`.
- Allocate service UID/GID and ports from `docs/service-registry.org` instead of inventing new values.

## Secrets, Persistence, And ZFS

- Reference secrets through `config.sops.secrets."path/to/secret".path`.
- Do not commit plaintext credentials, tokens, or generated secret material.
- Use `lib/persistence-helpers.nix` for impermanence bind-mount persistence.
- Use `lib/systemd-helpers.nix` for permission-fixing oneshot services.
- Use `lib/zfs-options.nix` and existing ZFS dataset patterns when adding persisted service data.

## Comments And Documentation

- Keep the existing style of concise, high-signal comments.
- Add comments when the constraint is non-obvious, cross-platform, or operationally important.
- Prefer explaining why a rule exists, not narrating obvious syntax.

## Rule Files Checked

- Existing repo-specific agent guidance: `CLAUDE.md`
- Cursor rules: none found in `.cursor/rules/` or `.cursorrules`
- Copilot instructions: none found at `.github/copilot-instructions.md`

## Practical Workflow For Agents

- Read the nearest similar file before editing.
- Make the smallest change that preserves current architecture.
- Run narrow validation first, then broader validation if the change touches shared code.
- If you add or modify a service, verify registry assignments and dependency assertions.
- If you touch shared module plumbing, validate at least one Linux host and one Darwin host when relevant.
