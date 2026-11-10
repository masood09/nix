# Hermes Desktop — Nous Research's native Electron shell for Hermes Agent
# (from numtide/llm-agents.nix).
#
# nixpkgs (stable or unstable) does not package hermes-desktop; llm-agents does,
# built daily against its own pinned nixpkgs-unstable. Home Manager has no
# module for it, so install the input's package through `home.packages`.
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.hermes-desktop.enable {
    home = {
      packages = [
        # Consumed via the input's own `packages` attr so it substitutes from
        # cache.numtide.com instead of rebuilding Electron against our nixpkgs.
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hermes-desktop
      ];
    };
  };
}
