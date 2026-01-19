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
  };

  config = {
    time.timeZone = "America/Toronto";
    zramSwap.enable = true;

    systemd.settings.Manager = {
      DefaultTimeoutStartSec = "20s";
      DefaultTimeoutStopSec = "10s";
    };

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "25.11";
  };
}
