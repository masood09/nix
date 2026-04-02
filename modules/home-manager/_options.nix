# Homelab program options — central registry of homelab.programs.* enable flags.
# Each program module reads its flag from here to decide whether to activate.
# Programs default to true (always-on) or false (opt-in) depending on how
# commonly they're used across machines.
{lib, ...}: {
  options = {
    homelab = {
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

        claude-code = {
          enable = lib.mkEnableOption "Whether to enable Claude Code.";
        };

        codex-cli = {
          enable = lib.mkEnableOption "Whether to enable Codex CLI.";
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

          showOnLogin = lib.mkOption {
            default = true;
            type = lib.types.bool;
            description = ''
              Whether to show fastfetch on interactive shell login.
            '';
          };

          zpools = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "ZFS pool names to show usage for in fastfetch output.";
          };

          zshInitOrder = lib.mkOption {
            type = lib.types.int;
            default = 650;
            description = "Order value for fastfetch in zsh initialization (lower runs earlier).";
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
            description = "GitHub username used for git configuration.";
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

        kitty = {
          enable = lib.mkEnableOption "Whether to enable kitty terminal.";
        };

        neovim = {
          enable = lib.mkEnableOption "Whether to enable neovim.";
        };

        oci-cli = {
          enable = lib.mkEnableOption "Whether to enable Oracle Cloud CLI.";
        };

        opentofu = {
          enable = lib.mkEnableOption "Whether to enable OpenTofu.";
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

        zen = {
          enable = lib.mkEnableOption "Whether to enable Zen browser.";

          containerProfile = lib.mkOption {
            type = lib.types.enum ["homelab" "family" "work"];
            default = "homelab";
            description = ''
              Which container/workspace set to configure.
              "homelab" — Personal, Homelab, Admin, Google (default).
              "family"  — Personal, Work, Google (for family members' machines).
              "work"    — Personal, Work, Google (for work machines).
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
              Whether to enable zsh.
            '';
          };
        };
      };
    };
  };
}
