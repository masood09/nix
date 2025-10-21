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
        modules = [path];
      };

    mkDarwinConfig = path:
      nix-darwin.lib.darwinSystem {
        specialArgs = {inherit inputs outputs vars;};
        modules = [path];
      };
  in {
    # Enables `nix fmt` at root of repo to format all nix files
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    darwinConfigurations = {
      murderbot = mkDarwinConfig ./machines/murderbot/configuration.nix;
    };

    nixosConfigurations = {
      oci-server1 = mkNixOSConfig ./machines/oci-server1/configuration.nix;
      oci-server2 = mkNixOSConfig ./machines/oci-server2/configuration.nix;
      oci-server3 = mkNixOSConfig ./machines/oci-server3/configuration.nix;
      oci-server4 = mkNixOSConfig ./machines/oci-server4/configuration.nix;
      isoserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs vars;};
        modules = [
          (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
          ./machines/isoserver/configuration.nix
        ];
      };
    };
  };
}
