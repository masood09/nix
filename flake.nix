{
  description = "Masood's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    impermanence.url = "github:nix-community/impermanence";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    catppuccin.url = "github:catppuccin/nix/release-25.05";

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fps = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    netbirdio-taps = {
      url = "github:netbirdio/homebrew-tap";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    ...
  } @ inputs: let
    inherit (self) outputs;
    vars = import ./vars.nix;

    systems = ["x86_64-linux" "aarch64-darwin" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    mkNixOSConfig = path:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs vars;};
        modules = [
          inputs.fps.nixosModules.programs-sqlite
          inputs.home-manager.nixosModules.home-manager
          inputs.authentik-nix.nixosModules.default
          path
        ];
      };

    mkDarwinConfig = path:
      nix-darwin.lib.darwinSystem {
        specialArgs = {inherit inputs outputs vars;};
        modules = [
          ({config, ...}: {
            homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
          })
          inputs.home-manager.darwinModules.home-manager
          path
        ];
      };
  in {
    # Enables `nix fmt` at root of repo to format all nix files
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    darwinConfigurations = {
      murderbot = mkDarwinConfig ./machines/murderbot/configuration.nix;
    };

    nixosConfigurations = {
      oci-db-server = mkNixOSConfig ./machines/oci-db-server/configuration.nix;
      oci-auth-server = mkNixOSConfig ./machines/oci-auth-server/configuration.nix;
      oci-vpn-server = mkNixOSConfig ./machines/oci-vpn-server/configuration.nix;
      nixiso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs vars;};
        modules = [
          (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
          ./machines/nixiso/configuration.nix
        ];
      };
    };
  };
}
