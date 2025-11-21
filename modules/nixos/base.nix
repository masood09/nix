{
  inputs,
  config,
  pkgs,
  vars,
  ...
}: {
  imports = [
    ./_packages.nix

    ./../../services/grafana-alloy.nix
    ./../../services/systemd-resolved.nix
    ./../../services/tailscale.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
    timeout = 10;
  };

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
  };

  users = {
    mutableUsers = false;

    users = {
      ${vars.userName} = {
        isNormalUser = true;
        description = vars.userName;
        extraGroups = ["networkmanager" "wheel"];
        openssh.authorizedKeys.keys = [
          vars.sshPublicKeyPersonal
          vars.sshPublicKeyRemoteBuilder
        ];
        shell = pkgs.bash;
        hashedPasswordFile = config.sops.secrets."user-password".path;
      };

      alloy = {
        isSystemUser = true;
        group = "alloy";
      };
    };

    groups.alloy = {};
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
    firewall.enable = true;
    networkmanager.enable = false;
  };

  time.timeZone = "America/Toronto";
  zramSwap.enable = true;

  environment.persistence."/nix/persist" = {
    # Hide these mounts from the sidebar of file managers
    hideMounts = true;

    directories = [
      "/var/log"
      # inspo: https://github.com/nix-community/impermanence/issues/178
      "/var/lib/nixos"
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
    ];
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
  systemd.extraConfig = ''
    DefaultLimitNOFILE=65536
  '';

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
