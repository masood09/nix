{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  boot = lib.mkIf homelabCfg.isEncryptedRoot {
    kernelParams = ["ip=dhcp"];

    initrd.network = {
      enable = true;

      ssh = {
        enable = true;
        shell = "/bin/cryptsetup-askpass";
        authorizedKeys = config.users.users.${homelabCfg.primaryUser.userName}.openssh.authorizedKeys.keys;
        hostKeys = ["/nix/secret/initrd/ssh_host_ed25519_key"];
      };
    };
  };
}
