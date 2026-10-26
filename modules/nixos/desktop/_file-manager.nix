# Lightweight graphical file manager for NixOS desktops.
{
  config,
  pkgs,
  ...
}: let
  userName = config.homelab.primaryUser.userName;
in {
  config = {
    home-manager = {
      backupFileExtension = "hm-backup";

      users.${userName} = {
        xdg = {
          mimeApps = {
            enable = true;
            defaultApplications = {
              "inode/directory" = "thunar.desktop";
            };
          };
        };
      };
    };

    programs = {
      thunar = {
        enable = true;
        plugins = [
          pkgs.thunar-archive-plugin
          pkgs.thunar-volman
        ];
      };
    };

    services = {
      gvfs = {
        enable = true;
      };

      tumbler = {
        enable = true;
      };
    };
  };
}
