# Flake entry point — multi-machine homelab (NixOS + nix-darwin + home-manager).
{
  description = "Masood's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # NixOS infrastructure
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # User environment
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop shell
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    # macOS
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    # Services
    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    headplane = {
      url = "github:tale/headplane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Applications
    # Claude Code CLI (hourly auto-updates, binary cache)
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    betterfox = {
      url = "github:yokoffing/Betterfox";
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

    systems = [
      "x86_64-linux"
      "aarch64-darwin"
      "aarch64-linux"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    # Applied to all NixOS, Darwin, and package builds
    sharedOverlays = [
      inputs.claude-code.overlays.default
      inputs.headplane.overlays.default
      (import ./nix/overlays/default.nix)
    ];

    # Shared NixOS configuration builder. Each machine provides its own
    # path (e.g. ./machines/heartbeat) which is appended to the common
    # module list containing disko, sops, home-manager, etc.
    mkNixOSConfig = path:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};

        modules = [
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          inputs.authentik-nix.nixosModules.default
          inputs.impermanence.nixosModules.impermanence
          inputs.headplane.nixosModules.headplane
          inputs.stylix.nixosModules.stylix

          (import ./nix/services/default.nix)

          {nixpkgs.overlays = sharedOverlays;}

          path
        ];
      };

    # Shared nix-darwin configuration builder for macOS machines.
    mkDarwinConfig = path:
      nix-darwin.lib.darwinSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.nix-homebrew.darwinModules.nix-homebrew
          inputs.home-manager.darwinModules.home-manager
          inputs.stylix.darwinModules.stylix

          {nixpkgs.overlays = sharedOverlays;}

          path
        ];
      };
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Custom packages defined in nix/pkgs/ (auto-discovered)
    packages = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = sharedOverlays;
        };
      in
        import ./nix/pkgs {
          inherit pkgs;
          inherit (pkgs) lib;
        }
    );

    # macOS machines
    darwinConfigurations = {
      "work-pantheon" = mkDarwinConfig ./machines/work-pantheon;
      murderbot = mkDarwinConfig ./machines/murderbot;
    };

    # NixOS servers and desktops
    nixosConfigurations = {
      accesscontrolsystem = mkNixOSConfig ./machines/accesscontrolsystem;
      commrelay = mkNixOSConfig ./machines/commrelay;
      meshcontrol = mkNixOSConfig ./machines/meshcontrol;
      watchfulsystem = mkNixOSConfig ./machines/watchfulsystem;

      caretaker = mkNixOSConfig ./machines/caretaker;
      commandmodule = mkNixOSConfig ./machines/commandmodule;
      heartbeat = mkNixOSConfig ./machines/heartbeat;
      trialunit = mkNixOSConfig ./machines/trialunit;

      sonic = mkNixOSConfig ./machines/sonic;

      # Minimal NixOS installer ISO with SSH key baked in
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
