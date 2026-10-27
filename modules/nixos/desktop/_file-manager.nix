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
              "application/pdf" = "io.github.scrambletools.prev.desktop";
              "image/avif" = "io.github.scrambletools.prev.desktop";
              "image/bmp" = "io.github.scrambletools.prev.desktop";
              "image/gif" = "io.github.scrambletools.prev.desktop";
              "image/jpeg" = "io.github.scrambletools.prev.desktop";
              "image/png" = "io.github.scrambletools.prev.desktop";
              "image/tiff" = "io.github.scrambletools.prev.desktop";
              "image/webp" = "io.github.scrambletools.prev.desktop";
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

    environment = {
      systemPackages = [
        pkgs.prev
      ];
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
