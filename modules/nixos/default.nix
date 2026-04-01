# Root NixOS module — shared by all NixOS machines.
# Imports every sub-module and defines the top-level homelab options
# (role, purpose) that other modules key off of.
{
  config,
  lib,
  ...
}: {
  imports = [
    # System-level modules
    ./_auto-update.nix
    ./_boot.nix
    ./_disks.nix
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
      role = lib.mkOption {
        default = "server";
        type = lib.types.enum ["desktop" "server"];
        description = ''
          The role of this machine. Could be server or desktop.
        '';
      };

      purpose = lib.mkOption {
        type = lib.types.str;
        default = "";
      };

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
        ];

        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
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
