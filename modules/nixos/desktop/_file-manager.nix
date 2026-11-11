# Lightweight graphical file manager for NixOS desktops.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  userName = config.homelab.primaryUser.userName;
in {
  config = lib.mkIf homelabCfg.desktop.enable {
    home-manager = {
      backupFileExtension = "hm-backup";

      users.${userName} = {
        xdg = {
          # Apps that set themselves as default (browsers, file managers,
          # "Open with… always") replace the managed symlink with a plain
          # file. HM then backs it up to mimeapps.list.hm-backup, and once
          # that backup exists every later activation fails on the clobber
          # check. The declared associations are authoritative, so overwrite.
          configFile = {
            "mimeapps.list" = {
              force = true;
            };
          };

          mimeApps = {
            enable = true;
            defaultApplications = {
              "application/pdf" = "run.prev.desktop";
              "image/avif" = "run.prev.desktop";
              "image/bmp" = "run.prev.desktop";
              "image/gif" = "run.prev.desktop";
              "image/jpeg" = "run.prev.desktop";
              "image/png" = "run.prev.desktop";
              "image/tiff" = "run.prev.desktop";
              "image/webp" = "run.prev.desktop";
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
