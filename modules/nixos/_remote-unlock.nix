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
        #
        # If `zpool import` reports the pool as MISSING (check with
        # `systemctl status zfs-import-<pool>.service`), that's a device
        # detection issue, not a key issue — a reboot is usually enough to
        # get the pool visible again. Once the pool is found, upstream's
        # zfs-import-<pool>.service runs its own internal `zfs load-key`
        # gated by `systemd-ask-password`, independent of anything typed
        # into the interactive shell — its prompt is bound to a console you
        # can't type into over SSH. Answer it with
        # `systemd-tty-ask-password-agent` from the SSH shell, which surfaces
        # any pending ask-password request there and lets you type the
        # passphrase directly.
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
