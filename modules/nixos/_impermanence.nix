{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options.homelab = {
    impermanence = lib.mkEnableOption "Enable Impermanence";
  };

  config = lib.mkIf homelabCfg.impermanence {
    environment.persistence."/nix/persist" = {
      # Hide these mounts from the sidebar of file managers
      hideMounts = true;

      directories = lib.mkIf (!homelabCfg.isRootZFS) [
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
  };
}
