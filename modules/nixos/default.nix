# Root NixOS module — shared by all NixOS machines.
# Imports every sub-module and defines the top-level homelab options
# (role, purpose) that other modules key off of.
{lib, ...}: {
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
    ./_users.nix

    # Desktop modules (gated on role == "desktop" internally)
    ./_desktop-hardware.nix
    ./_niri.nix

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
    };
  };

  config = {
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

        # nix-community cache for faster builds of community flake inputs
        substituters = [
          "https://cache.nixos.org/?priority=10"
          "https://nix-community.cachix.org"
        ];

        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
