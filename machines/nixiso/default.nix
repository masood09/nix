{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
    git
    gptfdisk
    parted
  ];

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfTOXZ6W+DhUQcytGQ1ob+eFPQwbyiTB8wXnRSiYqpK"
    ];
  };

  users.motd = ''
    Welcome to the Masood's NixOS ISO installer!

    To install the system, copy and paste the following command:

    sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/masood09/nix/main/install.sh)"

  '';

  security.sudo.wheelNeedsPassword = false;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  services.openssh = {
    enable = true;
  };

  networking.hostName = "nixiso";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
