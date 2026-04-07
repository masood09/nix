# opencode — AI coding assistant managed through Home Manager's native module.
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.opencode.enable {
    programs.opencode = {
      enable = true;

      # Track opencode from the flake's unstable nixpkgs input rather than the
      # system package set so desktop laptops pick up newer releases sooner.
      package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode;

      # The shared MCP registry still comes from `_mcp.nix`.
      enableMcpIntegration = true;
    };
  };
}
