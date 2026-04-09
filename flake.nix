# Flake entry point — multi-machine homelab (NixOS + nix-darwin + home-manager).
{
  description = "Masood's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Unstable channel — used by inputs that require latest nixpkgs (e.g. noctalia)
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

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
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
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
    # Pin below 0.7.x while the newer Headplane module shape regresses eval for
    # our Headscale integration on meshcontrol/trialunit.
    headplane = {
      url = "github:tale/headplane/v0.6.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Applications
    # Claude Code CLI (hourly auto-updates, binary cache)
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Codex CLI (hourly auto-updates, binary cache)
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
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
    # Noctalia desktop shell (requires unstable nixpkgs for latest Quickshell)
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs-unstable";
        };
      };
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
      inputs.codex-cli-nix.overlays.default
      inputs.headplane.overlays.default
      (import ./nix/overlays/default.nix)
      (import ./nix/overlays/darwin-setproctitle.nix)
    ];

    # Shared module list for all NixOS machines (servers + desktops).
    sharedNixOSModules = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
      inputs.authentik-nix.nixosModules.default
      inputs.impermanence.nixosModules.impermanence
      inputs.headplane.nixosModules.headplane
      inputs.stylix.nixosModules.stylix

      (import ./nix/services/default.nix)

      {nixpkgs.overlays = sharedOverlays;}
    ];

    # Desktop-only modules. Kept out of sharedNixOSModules because the
    # niri-flake NixOS module unconditionally injects its HM module (with
    # a default niri package) into home-manager.sharedModules, and the
    # noctalia flake wrapper sets programs.noctalia-shell.package via
    # mkDefault — both force heavyweight packages into every closure even
    # when the desktop is never enabled.
    desktopNixOSModules = [
      inputs.niri.nixosModules.niri
      {home-manager.sharedModules = [inputs.noctalia.homeModules.default];}
    ];

    # NixOS configuration builder for servers.
    mkNixOSConfig = path:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = sharedNixOSModules ++ [path];
      };

    # NixOS configuration builder for desktops. Extends mkNixOSConfig
    # with niri and noctalia flake modules that are too heavy for servers.
    mkNixOSDesktopConfig = path:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = sharedNixOSModules ++ desktopNixOSModules ++ [path];
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
      heartbeat = mkNixOSConfig ./machines/heartbeat;
      trialunit = mkNixOSConfig ./machines/trialunit;

      # Desktops — use mkNixOSDesktopConfig for niri + noctalia modules
      arrakis = mkNixOSDesktopConfig ./machines/arrakis;
      commandmodule = mkNixOSDesktopConfig ./machines/commandmodule;
      sonic = mkNixOSDesktopConfig ./machines/sonic;

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
