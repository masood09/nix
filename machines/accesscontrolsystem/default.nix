{
  config,
  inputs,
  outputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_networking.nix

    ./../../modules/nixos/base.nix
  ];

  sops.secrets = {
    "cloudflare-api-key" = {};
    "headscale-preauth-key" = {};
    "discord-zfs-webhook" = {};

    "restic-env" = {
      sopsFile = ./../../secrets/accesscontrolsystem-server.yaml;
    };
    "restic-repo" = {
      sopsFile = ./../../secrets/accesscontrolsystem-server.yaml;
    };
    "restic-password" = {
      sopsFile = ./../../secrets/accesscontrolsystem-server.yaml;
    };
  };

  homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;

    networking = {
      hostName = "accesscontrolsystem";
    };

    services = {
      tailscale = {
        enable = true;

        zfs = {
          enable = true;
          dataset = "rpool/root/var/lib/tailscale";
          properties = {
            recordsize = "16K";
          };
        };
      };
    };
  };

  fileSystems = {
    "/".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/var/lib/nixos".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/nix/persist".neededForBoot = true;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs homelabCfg;
    };

    useGlobalPkgs = true;
    useUserPackages = true;

    users = {
      ${homelabCfg.primaryUser.userName} = {
        imports = [
          ./../../modules/home-manager
        ];
      };
    };
  };
}
