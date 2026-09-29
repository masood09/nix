# Codex CLI — OpenAI's CLI coding assistant (from sadjow/codex-cli-nix)
{
  config,
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # This flake's checkout is trusted everywhere Codex runs; anything else is
  # opt-in per machine via `homelab.programs.codex-cli.trustedProjects`.
  trustedProjects =
    ["${config.home.homeDirectory}/code/nix"]
    ++ homelabCfg.programs.codex-cli.trustedProjects;
  configDir =
    if config.home.preferXdgDirectories
    then "${config.xdg.configHome}/codex"
    else "${config.home.homeDirectory}/.codex";
  configFile = lib.removePrefix "${config.home.homeDirectory}/" "${configDir}/config.toml";
  python = pkgs.python3.withPackages (ps: [ps.tomlkit]);
in {
  config = lib.mkIf homelabCfg.programs.codex-cli.enable {
    programs = {
      codex = {
        enable = true;
        # Input's prebuilt package (built against codex-cli-nix's own nixpkgs)
        # so it resolves from codex-cli.cachix.org instead of recompiling. The
        # overlay path (pkgs.codex) would rebuild against our nixpkgs.
        package = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

        # Keep Codex on the upstream HM module while layering in local defaults
        # and the shared MCP server registry managed by `_mcp.nix`.
        settings =
          {
            tui = {
              theme = "gruvbox-dark";
            };

            # Pre-answer the "trust this folder?" prompt for declared projects.
            projects = lib.genAttrs trustedProjects (_: {
              trust_level = "trusted";
            });
          }
          // lib.optionalAttrs (config.programs.mcp.servers != {}) {
            # nixpkgs 26.05's TOML format type rejects null-valued attributes,
            # and the shared MCP server submodule carries null defaults (e.g.
            # `url`/`enabled` for stdio servers). Strip nulls before serializing.
            mcp_servers = lib.mkDefault (
              lib.filterAttrsRecursive (_: v: v != null) config.programs.mcp.servers
            );
          };
      };
    };

    home = {
      # Keep the upstream-generated defaults, but let Codex own config.toml:
      # it writes trust decisions, model choices, and plugin settings there.
      file = {
        ${configFile} = {
          target = "${configDir}/config.hm.toml";
        };
      };

      activation = {
        codexConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
          run ${python}/bin/python - ${lib.escapeShellArg configDir} <<'PY'
          import os
          from pathlib import Path
          import sys
          import tempfile

          import tomlkit

          directory = Path(sys.argv[1])
          target = directory / "config.toml"
          defaults = tomlkit.parse((directory / "config.hm.toml").read_text())
          current = tomlkit.parse(target.read_text()) if target.exists() else tomlkit.document()

          # Nix owns declared values; preserve all other runtime settings and
          # comments. Removing a Nix setting leaves its last value in Codex.
          def merge(destination, source):
              for key, value in source.items():
                  if isinstance(value, dict) and isinstance(destination.get(key), dict):
                      merge(destination[key], value)
                  else:
                      destination[key] = value

          merge(current, defaults)
          # Atomic replacement also handles an old read-only store symlink.
          fd, temporary = tempfile.mkstemp(prefix=".config-", suffix=".toml", dir=directory)
          try:
              with os.fdopen(fd, "w") as output:
                  output.write(tomlkit.dumps(current))
              os.replace(temporary, target)
          finally:
              if os.path.exists(temporary):
                  os.unlink(temporary)
          PY
        '';
      };

      # bubblewrap is the Linux-only sandbox runtime Codex shells out to;
      # Darwin uses Apple's sandbox-exec instead, so skip it there.
      packages = lib.optionals pkgs.stdenv.isLinux [
        pkgs.bubblewrap
      ];
    };
  };
}
