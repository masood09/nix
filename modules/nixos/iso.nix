{config, ...}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./_packages.nix
  ];

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      homelabCfg.primaryUser.sshPublicKey
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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
