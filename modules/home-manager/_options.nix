# Homelab program options — central registry of homelab.programs.* enable flags.
# Each program module reads its flag from here to decide whether to activate.
# Programs default to true (always-on) or false (opt-in) depending on how
# commonly they're used across machines.
{
  config,
  lib,
  ...
}: let
  aiToolsCfg = config.homelab.programs.ai_tools;
  aiToolsEnabled = aiToolsCfg.enable;
  # Keep the existing per-tool flags as the module activation point so the
  # concrete Home Manager program modules stay small and machine configs can
  # move to a single AI registry without changing their internals.
  hasAiTool = tool: aiToolsEnabled && lib.elem tool aiToolsCfg.tools;
in {
  options = {
    homelab = {
      programs = {
        ai_tools = {
          enable = lib.mkEnableOption "Whether to enable AI tooling selection.";

          models = lib.mkOption {
            type = lib.types.listOf (
              lib.types.enum [
                "claude-code"
                "codex"
                "openai"
                "copilot"
                "openrouter"
                "zen"
              ]
            );
            default = [];
            description = ''
              Model providers to expose to AI-related integrations such as
              Noctalia's model-usage widget. Values are validated against a
              fixed enum so machine configs cannot drift from supported
              provider identifiers.
            '';
          };

          tools = lib.mkOption {
            type = lib.types.listOf (
              lib.types.enum [
                "claude-code"
                "codex"
                "opencode"
              ]
            );
            default = [];
            description = ''
              AI coding tools to install on this machine. Values are validated
              against a fixed enum so only supported tool modules can be
              selected.
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

        element-desktop = {
          enable = lib.mkEnableOption "Whether to enable Element Desktop.";

          baseUrl = lib.mkOption {
            type = lib.types.str;
            default = "https://chat.mantannest.com";
            description = "Default Matrix homeserver base URL for Element Desktop.";
          };

          serverName = lib.mkOption {
            type = lib.types.str;
            default = "chat.mantannest.com";
            description = "Default Matrix server name for Element Desktop.";
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
              type = lib.types.enum [
                "ssh"
                "gpg"
              ];
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

        opencode = {
          enable = lib.mkEnableOption "Whether to enable opencode.";
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
            type = lib.types.enum [
              "homelab"
              "family"
              "work"
            ];
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

  config = {
    homelab = {
      programs = {
        # `mkDefault` keeps the new aggregate selector as the preferred machine
        # interface while still allowing an explicit per-tool override if a
        # machine ever needs to diverge temporarily.
        claude-code = {
          enable = lib.mkDefault (hasAiTool "claude-code");
        };

        codex-cli = {
          enable = lib.mkDefault (hasAiTool "codex");
        };

        opencode = {
          enable = lib.mkDefault (hasAiTool "opencode");
        };
      };
    };
  };
}
