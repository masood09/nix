{
  inputs,
  config,
  pkgs,
  vars,
  lib,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops

    ./_packages.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
    timeout = 10;
  };

  nixpkgs.config.allowUnfree = true;

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
    age.sshKeyPaths = ["/nix/secret/initrd/ssh_host_ed25519_key"];
    secrets."user-password".neededForUsers = true;
    secrets."user-password" = {};
  };

  users.mutableUsers = false;

  users.users.${vars.userName} = {
    isNormalUser = true;
    description = vars.userName;
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = [
      vars.sshPublicKeyPersonal
    ];
    shell = pkgs.bash;
    hashedPasswordFile = config.sops.secrets."user-password".path;
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
      openFirewall = true;
    };
    fstrim.enable = true;
  };

  networking = {
    firewall.enable = false;
    networkmanager.enable = false;
  };

  security.sudo.wheelNeedsPassword = false;
  time.timeZone = "America/Toronto";
  zramSwap.enable = true;

  environment.persistence."/nix/persist" = {
    # Hide these mounts from the sidebar of file managers
    hideMounts = true;

    directories = [
      "/var/log"
      # inspo: https://github.com/nix-community/impermanence/issues/178
      "/var/lib/nixos"
      (
        if config.networking.hostName == "oci-server1"
        then "/var/lib/postgresql"
        else null
      )
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
    ];
  };

  # Ensure /var/lib/postgresql exists with proper ownership and permissions
  systemd.tmpfiles.rules = lib.mkIf (config.networking.hostName == "oci-server1") [
    "d /var/lib/postgresql 0755 postgres postgres -"
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
