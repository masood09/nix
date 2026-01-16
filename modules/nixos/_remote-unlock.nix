{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  boot = lib.mkIf homelabCfg.isEncryptedRoot {
    initrd.network = {
      enable = true;

      ssh = {
        enable = true;
        shell = lib.mkIf (!homelabCfg.isRootZFS) "/bin/cryptsetup-askpass";
        authorizedKeys = config.users.users.${homelabCfg.primaryUser.userName}.openssh.authorizedKeys.keys;
        hostKeys = ["/nix/secret/initrd/ssh_host_ed25519_key"];
        port = homelabCfg.services.ssh.listenPortBoot;
      };
    };
  };
}
