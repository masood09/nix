# opencode — AI coding assistant managed through Home Manager's native module
# (package from numtide/llm-agents.nix)
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.opencode.enable {
    programs = {
      opencode = {
        enable = true;

        # llm-agents builds this daily against its own pinned nixpkgs and pushes
        # the result to cache.numtide.com, so it substitutes instead of
        # recompiling against our nixpkgs (its overlay would rebuild). The
        # package is the upstream release binary, wrapped so fzf and ripgrep are
        # on PATH, and installs only bin/opencode — there is no broken Fish
        # completion to strip as there was with the nixpkgs build, and
        # `overrideAttrs` here would make a new derivation instead of
        # substituting.
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;

        settings = {
          "$schema" = "https://opencode.ai/config.json";
          model = "ixian-strata/qwen3.8-flash-next-iq2_xs";

          provider = {
            ixian-strata = {
              npm = "@ai-sdk/openai-compatible";
              name = "Ixian Strata";
              options = {
                # Caddy on ixian (LAN-only DNS); see modules/services/strata.
                baseURL = "https://ai.mantannest.com/v1";
              };
              models = {
                "qwen3.8-flash-next-iq2_xs" = {
                  name = "Qwen3.8 Flash Next IQ2_XS";
                  limit = {
                    context = 262144;
                    output = 4096;
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
