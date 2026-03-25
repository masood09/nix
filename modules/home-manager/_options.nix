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

        motd = {
          enable = lib.mkEnableOption "Show a custom MOTD on interactive shells.";

          networkInterfaces = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Network interfaces to display IP addresses for in the MOTD.";
          };

          zshInitOrder = lib.mkOption {
            type = lib.types.int;
            default = 650;
            description = "Order value for the MOTD in zsh initialization (lower runs earlier).";
          };
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

        stylix = {
          enable = lib.mkOption {
            default = true;
            type = lib.types.bool;
            description = ''
              Whether to enable stylix base16 theming.
            '';
          };

          polarity = lib.mkOption {
            default = "dark";
            type = lib.types.enum ["dark" "light"];
            description = ''
              Theme polarity (dark or light mode).
            '';
          };

          scheme = lib.mkOption {
            default = "catppuccin-mocha";
            type = lib.types.either lib.types.str lib.types.path;
            description = ''
              Base16 color scheme. Either a scheme name from the base16-schemes
              package (e.g. "catppuccin-mocha", "nord") or a path to a custom
              Base16 YAML file (e.g. ../../nix/themes/sonic-dark.yaml).
            '';
          };

          wallpaper = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              Path to wallpaper image. Stylix will extract colors from this if set.
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
