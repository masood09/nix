# OpenTofu — open-source infrastructure-as-code tool.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: {
  home = {
    packages = lib.mkIf homelabCfg.programs.opentofu.enable [
      pkgs.opentofu
    ];
  };
}
