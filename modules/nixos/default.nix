{lib, ...}: {
  imports = [
    ./_auto-update.nix
    ./_boot.nix
    ./_disks.nix
    ./_impermanence.nix
    ./_networking.nix
    ./_nixpkgs.nix
    ./_packages.nix
    ./_prune-system-generations.nix
    ./_reboot-required-check.nix
    ./_remote-unlock.nix
    ./_security.nix
    ./_sops.nix
    ./_users.nix

    ./zfs

    ./../services
  ];

  options.homelab = {
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

  config = {
    time.timeZone = "America/Toronto";
    zramSwap.enable = true;

    nix = {
      settings = {
        substituters = [
          "https://cache.nixos.org/?priority=10"
          "https://nix-community.cachix.org"
        ];

        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };

    systemd.settings.Manager = {
      DefaultTimeoutStartSec = "20s";
      DefaultTimeoutStopSec = "10s";
    };

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "25.11";
  };
}
