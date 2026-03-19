# Remote unlock — SSH server in the initrd for unlocking encrypted disks.
# On encrypted-root machines, an SSH daemon starts during early boot so the
# disk passphrase can be entered remotely (port 2222 by default).
# Non-ZFS machines drop into cryptsetup-askpass; ZFS machines use zfs load-key.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options.homelab.boot.ssh = {
    listenPort = lib.mkOption {
      default = 2222;
      type = lib.types.port;
      description = "The port of the SSH server for remote boot unlock.";
    };
  };

  config = lib.mkIf homelabCfg.isEncryptedRoot {
    boot = {
      initrd.network = {
        enable = true;

        ssh = {
          enable = true;
          shell = lib.mkIf (!homelabCfg.isRootZFS) "/bin/cryptsetup-askpass";
          authorizedKeys = config.users.users.${homelabCfg.primaryUser.userName}.openssh.authorizedKeys.keys;
          hostKeys = ["/nix/secret/initrd/ssh_host_ed25519_key"];
          port = homelabCfg.boot.ssh.listenPort;
        };
      };
    };
  };
}
