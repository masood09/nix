{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  inherit (homelabCfg) role;
in {
  home = {
    packages = with pkgs;
      [
        age
        findutils
        gnutar
        sops
        stow
        wget
        xz
      ]
      ++ lib.optionals (role == "server") [
        # Packages to be installed only on servers
      ]
      ++ lib.optionals (role == "desktop") [
        # Packages to be installed only on desktops (laptops/macs)
        alejandra
        go
        just
        jq
        oci-cli
        opentofu
        restic
        statix

        # Fonts
        julia-mono
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
        nerd-fonts.symbols-only
        nerd-fonts.hack
      ]
      ++ lib.optionals (role == "desktop" && pkgs.stdenv.isDarwin) [
        nixos-rebuild
      ];
  };
}
