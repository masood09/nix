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

        # OpenCode 2, not llm-agents' v1 `opencode`: the existing config and
        # data under ~/.config/opencode and ~/.local/share/opencode are in v2
        # format, which v1 cannot read. llm-agents builds it daily against its
        # own pinned nixpkgs and pushes it to cache.numtide.com, so it
        # substitutes instead of recompiling. It installs the binary as
        # bin/opencode2 so it can coexist with v1; the symlinkJoin only adds an
        # `opencode` link to it, keeping the usual command name and giving the
        # HM module's wrappers (which call bin/opencode) a target. The
        # symlinkJoin builds locally in seconds; opencode2 itself still
        # substitutes, since nothing overrides it.
        package = let
          opencode2 = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
        in
          pkgs.symlinkJoin {
            name = "opencode2-${opencode2.version}";
            inherit (opencode2) version;
            paths = [
              opencode2
            ];
            postBuild = ''
              ln -s $out/bin/opencode2 $out/bin/opencode
            '';
            meta =
              opencode2.meta
              // {
                mainProgram = "opencode";
              };
          };

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
