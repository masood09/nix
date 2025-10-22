{
  pkgs,
  inputs,
  osConfig,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in {
  home = {
    packages = with pkgs;
      [
        age
        coreutils
        fd
        findutils
        fzf
        gnutar
        iperf3
        ripgrep
        sops
        stow
        wget
        xz
      ]
      ++ (
        if
          builtins.substring 0 3 osConfig.networking.hostName
          == "oci"
          || builtins.substring 0 3 osConfig.networking.hostName == "pve"
        then [
          # Below packages are for servers only; excluded from personal machines
        ]
        else [
          # Below packages are for personal machines only; excluded from servers
          # inspo: https://discourse.nixos.org/t/how-to-use-hostname-in-a-path/42612/3
          ansible
          cmake
          coreutils-prefixed
          fluxcd
          glibtool
          go
          gomodifytags
          gopls
          gore
          gotests
          jsbeautifier
          just
          jq
          k9s
          kubectl
          kubernetes-helm
          multimarkdown
          nil
          nixfmt-rfc-style
          nixos-rebuild # need for macOS
          oci-cli
          opentofu
          pkgs-unstable.vscode-json-languageserver
          shellcheck
          statix
          stylelint
          talosctl
          terraform
          terraform-ls
          yaml-language-server
          yq-go
        ]
      );
  };
}
