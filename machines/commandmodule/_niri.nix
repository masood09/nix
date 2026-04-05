# commandmodule — machine-specific Niri output configuration.
{
  config,
  lib,
  ...
}: let
  niriEnabled = config.homelab.desktop.niri.enable or false;
in {
  config = lib.mkIf niriEnabled {
    home-manager = {
      users.${config.homelab.primaryUser.userName}.programs.niri.settings.outputs = {
        # Laptop panel sits to the right of the shared LG 4K display.
        # 3072 = 3840 / 1.25, i.e. the external monitor's logical width.
        "eDP-1" = {
          mode = {
            width = 1920;
            height = 1080;
            refresh = 59.999;
          };
          scale = 1.0;
          transform.rotation = 0;
          position = {
            x = 3072;
            y = 0;
          };
        };
      };
    };
  };
}
