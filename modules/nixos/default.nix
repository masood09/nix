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
    ./_impermanence.nix
    ./_networking.nix
    ./_nixpkgs.nix
    ./_packages.nix
    ./_remote-unlock.nix
    ./_security.nix
    ./_sops.nix
    ./_users.nix

    ./zfs

    ./../services
  ];

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

  time.timeZone = "America/Toronto";
  zramSwap.enable = true;

  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "20s";
    DefaultTimeoutStopSec = "10s";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
