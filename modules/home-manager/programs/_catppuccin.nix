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
