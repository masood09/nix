{
  config,
  inputs,
  pkgs,
  ...
}: let
  userName = "masoodahmed";
  sshPublicKeyPersonal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfTOXZ6W+DhUQcytGQ1ob+eFPQwbyiTB8wXnRSiYqpK";
in {
  imports = [
    inputs.nixpkgs.nixosModules.notDetected
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    # inputs.impermanence.nixosModules.impermanence

    ./disko.nix
    ./hardware-configuration.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    dontPatchELF = true;

    packageOverrides = pkgs: {
      inherit (pkgs) stdenv;
    };

    documentation.enable = false;
    man.enable = false;
    info.enable = false;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  sops = {
    defaultSopsFile = ./../../secrets/secrets.yaml;
    age.sshKeyPaths = ["/nix/secret/age/ssh_ed25519_key"];
    secrets."user-password".neededForUsers = true;
    secrets."user-password" = {};
    secrets."headscale-preauth-key" = {};
  };

  users = {
    mutableUsers = false;

    users = {
      ${userName} = {
        isNormalUser = true;
        description = userName;
        extraGroups = ["networkmanager" "wheel"];
        shell = pkgs.bash;
        hashedPasswordFile = config.sops.secrets."user-password".path;

        openssh.authorizedKeys.keys = [
          sshPublicKeyPersonal
        ];
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = true;

      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    fstrim.enable = true;

    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."headscale-preauth-key".path;

      extraUpFlags = [
        "--login-server=https://headscale.mantannest.com"
      ];
    };
  };

  networking = {
    firewall.enable = true;
    hostId = "64afc685";
    hostName = "nastest";
  };

  time.timeZone = "America/Toronto";

  # environment.persistence."/nix/persist" = {
  #   # Hide these mounts from the sidebar of file managers
  #   hideMounts = true;

  #   files = [
  #     "/etc/machine-id"
  #     "/etc/ssh/ssh_host_ed25519_key.pub"
  #     "/etc/ssh/ssh_host_ed25519_key"
  #     "/etc/ssh/ssh_host_rsa_key.pub"
  #     "/etc/ssh/ssh_host_rsa_key"
  #     "/etc/zfs/zpool.cache"
  #   ];
  # };

  fileSystems = {
    "/var/log".neededForBoot = true;
    "/var/lib/nixos".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/nix/persist".neededForBoot = true;
  };

  security = {
    sudo.wheelNeedsPassword = false;

    # Increase system-wide file descriptor limit
    pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65536";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "65536";
      }
    ];
  };

  # For systemd services (like nix-daemon)
  systemd = {
    extraConfig = ''
      DefaultLimitNOFILE=65536
      DefaultTimeoutStartSec=20s
      DefaultTimeoutStopSec=10s
    '';

    services.zfs-mount.enable = false;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";

  programs.fuse.userAllowOther = true;
}
