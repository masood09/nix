# Bambu Studio — machine-local 3D printer slicer for usul.
{
  config,
  inputs,
  pkgs,
  ...
}: let
  user = config.homelab.primaryUser.userName;
  bambuStudio = inputs.bambu-studio.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home-manager = {
    users = {
      ${user} = {
        home = {
          packages = [bambuStudio];
        };
      };
    };
  };
}
