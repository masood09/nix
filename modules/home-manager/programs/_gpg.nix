{
  homelabCfg,
  lib,
  ...
}: let
  gpgEnabled = homelabCfg.programs.gpg.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;
in {
  programs = lib.mkIf gpgEnabled {
    gpg = {
      enable = true;

      scdaemonSettings = {
        allow-admin = true;
        disable-ccid = true;
        card-timeout = "1";
      };
    };

    bash = lib.mkIf gpgEnabled {
      initExtra = ''
        # Use gpg-agent as SSH agent locally; keep forwarded agent when in SSH.
        if [[ $- == *i* ]] && [[ -z "''${SSH_CLIENT}''${SSH_CONNECTION}''${SSH_TTY}" ]]; then
          export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        fi
      '';
    };

    fish = lib.mkIf (gpgEnabled && fishEnabled) {
      interactiveShellInit = ''
        # Use gpg-agent as SSH agent locally; keep forwarded agent when in SSH.
        if status --is-interactive
          if not set -q SSH_CLIENT; and not set -q SSH_CONNECTION; and not set -q SSH_TTY
            set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
          end
        end
      '';
    };

    zsh = lib.mkIf (gpgEnabled && zshEnabled) {
      initContent = lib.mkOrder 1000 ''
        # Use gpg-agent as SSH agent locally; keep forwarded agent when in SSH.
        if [[ -o interactive ]] && [[ -z "''${SSH_CLIENT}''${SSH_CONNECTION}''${SSH_TTY}" ]]; then
          export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        fi
      '';
    };
  };

  services = lib.mkIf gpgEnabled {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableScDaemon = true;
      defaultCacheTtl = 7200;
      maxCacheTtl = 86400;

      enableBashIntegration = true;
      enableFishIntegration = fishEnabled;
      enableZshIntegration = zshEnabled;
    };
  };
}
