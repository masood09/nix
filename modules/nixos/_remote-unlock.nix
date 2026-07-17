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
  options = {
    homelab = {
      boot = {
        ssh = {
          listenPort = lib.mkOption {
            default = 2222;
            type = lib.types.port;
            description = "The port of the SSH server for remote boot unlock.";
          };
        };
      };
    };
  };

  config = lib.mkIf homelabCfg.isEncryptedRoot {
    boot = {
      initrd = {
        network = {
          enable = true;

          ssh = {
            enable = true;
            authorizedKeys = config.users.users.${homelabCfg.primaryUser.userName}.openssh.authorizedKeys.keys;
            hostKeys = ["/nix/secret/initrd/ssh_host_ed25519_key"];
            port = homelabCfg.boot.ssh.listenPort;
          };
        };

        # Drop non-ZFS SSH sessions straight into systemd's password agent so
        # the LUKS passphrase can be entered remotely. Under systemd stage-1
        # initrd (the nixos-26.05 default) the old /bin/cryptsetup-askpass login
        # shell is unavailable — systemd-tty-ask-password-agent is its analog.
        # ZFS machines set no shell and use `zfs load-key` from the initrd shell.
        systemd = {
          users = {
            root = {
              shell =
                lib.mkIf (!homelabCfg.isRootZFS)
                "${config.boot.initrd.systemd.package}/bin/systemd-tty-ask-password-agent";
            };
          };
        };
      };
    };
  };
}
