# Catppuccin — Mocha colour scheme applied globally via the catppuccin flake.
# Themes terminal tools (bat, btop, starship, etc.) when enabled.
{
  homelabCfg,
  inputs,
  ...
}: {
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin = {
    inherit (homelabCfg.programs.catppuccin) enable;
  };
}
