{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./_auto-update.nix
    ./_boot.nix
    ./_networking.nix
    ./_packages.nix
    ./_remote-unlock.nix
    ./_users.nix

    ./../services/alloy
    ./../services/ssh
  ];

  nixpkgs.config = {
    allowUnfree = true;
    dontPatchELF = true;

    packageOverrides = pkgs: {
      inherit (pkgs) stdenv;
    };

    documentation.enable = false;
    man.enable = false;
    info.enable = false;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  sops = {
    defaultSopsFile = ./../../secrets/secrets.yaml;
    age.sshKeyPaths = ["/nix/secret/age/ssh_ed25519_key"];
    secrets."user-password".neededForUsers = true;
    secrets."user-password" = {};
  };

  time.timeZone = "America/Toronto";
  zramSwap.enable = true;

  # TODO: Move this to impermanence file.
  environment.persistence."/nix/persist" = {
    # Hide these mounts from the sidebar of file managers
    hideMounts = true;

    directories = lib.mkIf (!homelabCfg.isRootZFS) [
      "/var/log"
      # inspo: https://github.com/nix-community/impermanence/issues/178
      "/var/lib/nixos"
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
    ];
  };

  # TODO: Move this to _security.nix file.
  security = {
    sudo.wheelNeedsPassword = false;

    # Increase system-wide file descriptor limit
    pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65536";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "65536";
      }
    ];
  };

  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "20s";
    DefaultTimeoutStopSec = "10s";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
