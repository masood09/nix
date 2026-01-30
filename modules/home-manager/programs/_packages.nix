{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  inherit (homelabCfg) role;

  globalPkgs = with pkgs; [
    # Packages that are global.
  ];
in {
  home = {
    packages =
      globalPkgs
      ++ lib.optionals (role == "server") (with pkgs; [
        # Packages to be installed only on servers
      ])
      ++ lib.optionals (role == "desktop") (with pkgs; [
        # Packages to be installed only on desktops (laptops/macs)
        age
        alejandra
        findutils
        gnutar
        go
        just
        jq
        oci-cli
        opentofu
        restic
        sops
        statix
        stow
        xz
        awscli2

        # Fonts
        julia-mono
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
        nerd-fonts.symbols-only
        nerd-fonts.hack
      ])
      ++ lib.optionals (role == "desktop" && pkgs.stdenv.isDarwin) (with pkgs; [
        nixos-rebuild
      ]);
  };
}
