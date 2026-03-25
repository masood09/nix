# OCI CLI — Oracle Cloud Infrastructure command-line interface.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: {
  home = {
    packages = lib.mkIf homelabCfg.programs.oci-cli.enable [
      pkgs.oci-cli
    ];
  };
}
