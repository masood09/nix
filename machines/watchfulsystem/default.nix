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
    ./../../modules/services
  ];

  sops.secrets = {
    "cloudflare-api-key" = {};
  };

  homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;

    networking = {
      hostName = "watchfulsystem";
    };

    services = {
      acme = {
        cloudflareAPIKeyPath = config.sops.secrets."cloudflare-api-key".path;
      };

      caddy = {
        enable = true;
      };

      uptime-kuma = {
        enable = true;
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
