{
  description = "Masood's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    impermanence.url = "github:nix-community/impermanence";
    disko.url = "github:nix-community/disko";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    homebrew-jackielii-tap = {
      url = "github:jackielii/homebrew-tap";
      flake = false;
    };

    homebrew-sketchybar-tap = {
      url = "github:FelixKratz/homebrew-formulae";
      flake = false;
    };

    homebrew-emacs-plus = {
      url = "github:d12frosted/homebrew-emacs-plus";
      flake = false;
    };

    homebrew-koekeishiya-yabai = {
      url = "github:koekeishiya/homebrew-formulae";
      flake = false;
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

    catppuccin.url = "github:catppuccin/nix/release-25.11";

    authentik-nix = {
      # url = "github:nix-community/authentik-nix";
      url = "github:Pentusha/authentik-nix";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    ...
  } @ inputs: let
    inherit (self) outputs;

    systems = [
      "x86_64-linux"
      "aarch64-darwin"
      "aarch64-linux"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    mkNixOSConfig = path:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};

        modules = [
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          inputs.authentik-nix.nixosModules.default
          inputs.impermanence.nixosModules.impermanence

          ./config/homelab

          path
        ];
      };

    mkDarwinConfig = path:
      nix-darwin.lib.darwinSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.nix-homebrew.darwinModules.nix-homebrew
          inputs.home-manager.darwinModules.home-manager

          ./config/homelab

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
      accesscontrolsystem = mkNixOSConfig ./machines/accesscontrolsystem;
      meshcontrol = mkNixOSConfig ./machines/meshcontrol;
      watchfulsystem = mkNixOSConfig ./machines/watchfulsystem;

      heartbeat = mkNixOSConfig ./machines/heartbeat;

      caretaker = mkNixOSConfig ./machines/caretaker/configuration.nix;
      failsafeunit = mkNixOSConfig ./machines/failsafeunit;
      nastest = mkNixOSConfig ./machines/nastest;

      pve-monitoring = mkNixOSConfig ./machines/pve-monitoring/configuration.nix;

      nixiso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
          ./machines/nixiso
        ];
      };
    };
  };
}
