{lib, ...}: {
  imports = [
    ./_git.nix
  ];

  options.homelab = {
    programs = {
      bash = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable bat.
          '';
        };
      };

      bat = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable bat.
          '';
        };
      };

      btop = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable btop.
          '';
        };
      };

      catppuccin = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable catppuccin.
          '';
        };
      };

      direnv = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable direnv.
          '';
        };
      };

      emacs = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
          description = ''
            Whether to enable emacs.
          '';
        };
      };

      eza = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable eza.
          '';
        };
      };

      fastfetch = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable fastfetch.
          '';
        };
      };

      fd = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable fd.
          '';
        };
      };

      fish = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable fish shell.
          '';
        };
      };

      fzf = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable fzf.
          '';
        };
      };

      ripgrep = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable ripgrep.
          '';
        };
      };

      zoxide = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable zoxide.
          '';
        };
      };

      zsh = {
        enable = lib.mkOption {
          default = false;
          type = lib.types.bool;
          description = ''
            Whether to enable bat.
          '';
        };
      };
    };
  };
}
