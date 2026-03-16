{lib, ...}: {
  options.homelab = {
    programs = {
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

      claude-code = {
        enable = lib.mkEnableOption "Enable Claude Code";
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
        enable = lib.mkEnableOption "Whether to enable emacs.";
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
        enable = lib.mkEnableOption "Whether to enable fish shell.";
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

      git = {
        enable = lib.mkEnableOption "Whether to enable git.";

        userName = lib.mkOption {
          default = "Masood Ahmed";
          type = lib.types.str;
          description = ''
            The userName option for git.
          '';
        };

        userEmail = lib.mkOption {
          default = "me@ahmedmasood.com";
          type = lib.types.str;
          description = ''
            The userEmail option for git.
          '';
        };

        githubUsername = lib.mkOption {
          default = "masood09";
          type = lib.types.str;
        };

        signing = {
          method = lib.mkOption {
            type = lib.types.enum ["ssh" "gpg"];
            default = "ssh";
            description = "Git commit signing method. 'ssh' (default) or 'gpg' (OpenPGP).";
          };

          gpgKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "GPG key id or fingerprint to use when signing.method = 'gpg'.";
          };

          sshKeyFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "SSH public key file to use when signing.method = 'ssh'. Defaults to ~/.ssh/id_ed25519.pub if null.";
          };
        };
      };

      gpg = {
        enable = lib.mkEnableOption "Whether to enable GPG.";
      };

      motd = {
        enable = lib.mkEnableOption "Show a custom MOTD on interactive shells.";

        networkInterfaces = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };

        zshInitOrder = lib.mkOption {
          type = lib.types.int;
          default = 650;
        };
      };

      neovim = {
        enable = lib.mkEnableOption "Whether to enable neovim.";
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

      starship = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable starship prompt.
          '';
        };
      };

      tmux = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable tmux.
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
          default = true;
          type = lib.types.bool;
          description = ''
            Whether to enable bat.
          '';
        };
      };
    };
  };
}
