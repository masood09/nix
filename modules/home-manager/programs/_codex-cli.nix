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

            # Pre-answer the "trust this folder?" prompt. Codex cannot persist
            # the answer itself because HM makes config.toml read-only.
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
      # bubblewrap is the Linux-only sandbox runtime Codex shells out to;
      # Darwin uses Apple's sandbox-exec instead, so skip it there.
      packages = lib.optionals pkgs.stdenv.isLinux [
        pkgs.bubblewrap
      ];
    };
  };
}
