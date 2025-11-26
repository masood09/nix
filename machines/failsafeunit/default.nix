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

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
    ./../../modules/nixos/remote-unlock.nix

    ./../../modules/services
  ];

  sops.secrets = {
    "cloudflare-api-key" = {};
    "MiniIORootCreds" = {
      owner = "minio";
      sopsFile = ./../../secrets/failsafeunit.yaml;
    };
  };


  homelab = {
    networking = {
      hostName = "failsafeunit";
    };

    services = {
      acme = {
        cloudflareAPIKeyPath = config.sops.secrets."cloudflare-api-key".path;
      };

      caddy = {
        enable = true;
      };

      immich = {
        enable = true;
        mediaLocation = "/mnt/DataStore/Apps/Immich";
      };

      minio = {
        enable = true;
        browser = true;
        consoleAddress = "0.0.0.0";
        listenAddress = "0.0.0.0";
        openFirewall = true;
        rootCredentialsFile = config.sops.secrets."MiniIORootCreds".path;

        dataDir = [
          "/mnt/DataStore/Apps/MinIO/"
        ];
      };

      postgresql = {
        enable = true;
        dataDir = "/mnt/DataStore/Apps/PostgreSQL_16";
      };
    };
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

  # For systemd services (like nix-daemon)
  systemd = {
    extraConfig = ''
      DefaultLimitNOFILE=65536
      DefaultTimeoutStartSec=20s
      DefaultTimeoutStopSec=10s
    '';
  };
}
