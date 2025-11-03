{
  config,
  inputs,
  outputs,
  vars,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.impermanence.nixosModules.impermanence

    ./../../modules/nixos/pve-hardware-configuration.nix

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
    ./../../modules/nixos/remote-unlock.nix

    ./../../services/systemd-resolved.nix
    ./../../services/vaultwarden.nix
    ./../../services/tailscale.nix
    ./../../services/prometheus-exporter-node.nix
  ];

  sops.secrets = {
    "restic-env-file" = {
      sopsFile = ./../../secrets/hl-restic.yaml;
    };
    "restic-oci-repo" = {
      sopsFile = ./../../secrets/hl-restic.yaml;
    };
    "restic-encrypt-password" = {
      sopsFile = ./../../secrets/hl-restic.yaml;
    };
  };

  services = {
    qemuGuest.enable = true;

    restic.backups.homelab = {
      initialize = true;
      environmentFile = config.sops.secrets."restic-env-file".path;
      repositoryFile = config.sops.secrets."restic-oci-repo".path;
      passwordFile = config.sops.secrets."restic-encrypt-password".path;

      paths = [
        "/var/lib/vaultwarden"
        "/var/backup/postgresql/"
      ];

      pruneOpts = [
        "--keep-daily 24"
        "--keep-weekly 7"
        "--keep-monthly 30"
        "--keep-yearly 12"
      ];

      timerConfig = {
        OnCalendar = "*-*-* *:30:00";
        Persistent = true;
      };
    };
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs vars;};
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      ${vars.userName} = {
        imports = [
          ./../../modules/home-manager/base.nix
          ./../../modules/home-manager/packages-server.nix
        ];
      };
    };
  };

  networking = {
    hostName = "pve-server-1";
    dhcpcd.enable = false;
    useNetworkd = true;
    interfaces.ens18.useDHCP = true;
  };
}
