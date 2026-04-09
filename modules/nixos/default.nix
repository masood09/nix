# Root NixOS module — shared by all NixOS machines.
# Imports every sub-module and the cross-platform homelab options
# (role, purpose, primaryUser, networking) from modules/shared/options.nix.
# NixOS-only options (hardware.isVM) are defined here.
{
  config,
  lib,
  ...
}: {
  imports = [
    ../shared/options.nix

    # System-level modules
    ./_auto-update.nix
    ./_boot.nix
    ./_disks.nix
    ./_gc.nix
    ./_impermanence.nix
    ./_networking.nix
    ./_nixpkgs.nix
    ./_packages.nix
    ./_reboot-required-check.nix
    ./_remote-unlock.nix
    ./_security.nix
    ./_sops.nix
    ./_stylix.nix
    ./_users.nix

    # Desktop modules (gated on role == "desktop" internally)
    ./desktop

    # ZFS pool management
    ./zfs

    # Declarative service modules (each has its own enable flag)
    ./../services
  ];

  options = {
    homelab = {
      hardware = {
        isVM = lib.mkEnableOption "virtual machine mode (disables fwupd and other bare-metal services)";
      };
    };
  };

  config = {
    # Firmware updates — fwupd pulls from LVFS; run `fwupdmgr update` to apply
    # Disabled on VMs where there is no physical firmware to update.
    services = {
      fwupd = lib.mkIf (!config.homelab.hardware.isVM) {
        enable = true;
      };
    };

    time = {
      timeZone = "America/Toronto";
    };

    zramSwap = {
      enable = true;
    };

    # Core nix daemon settings. Automatic garbage collection lives in the
    # sibling `_gc.nix` module to keep the schedule isolated from cache config.
    nix = {
      settings = {
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;

        # Binary caches for faster builds
        substituters = [
          "https://cache.nixos.org/?priority=10"
          "https://nix-community.cachix.org"
          "https://niri.cachix.org" # sodiboo/niri-flake
          "https://claude-code.cachix.org" # sadjow/claude-code-nix (hourly updates)
          "https://codex-cli.cachix.org" # sadjow/codex-cli-nix (hourly updates)
          "https://noctalia.cachix.org" # noctalia-dev/noctalia-shell
        ];

        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
          "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };
    };

    systemd = {
      settings = {
        # Shorter timeouts so failed services don't block boot/shutdown
        Manager = {
          DefaultTimeoutStartSec = "20s";
          DefaultTimeoutStopSec = "10s";
        };
      };
    };

    system = {
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "25.11";
    };
  };
}
