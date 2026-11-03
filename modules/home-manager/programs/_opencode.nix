# opencode — AI coding assistant managed through Home Manager's native module.
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

        # Track opencode from the flake's unstable nixpkgs input rather than the
        # system package set so desktop laptops pick up newer releases sooner.
        package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode.overrideAttrs (oldAttrs: {
          # OpenCode 2.1.4 currently ships a truncated Fish completion file.
          # A syntax error while Fish sources vendor completions is noisy at
          # every shell start, while OpenCode itself remains usable without
          # that optional completion.
          postInstall =
            (oldAttrs.postInstall or "")
            + ''
              rm -f $out/share/fish/vendor_completions.d/opencode.fish
            '';
        });

      };
    };
  };
}
