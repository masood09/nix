# Git — commit signing (SSH or GPG), delta diff viewer, and allowed signers.
# All SSH public keys from primaryUser.sshPublicKeys are added to the
# git allowed-signers file so commits signed from any machine verify correctly.
{
  config,
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  gitCfg = homelabCfg.programs.git;

  keys = homelabCfg.primaryUser.sshPublicKeys;
  email = gitCfg.userEmail;

  # Generate allowed_signers file with all SSH keys for commit verification
  signersFile = pkgs.writeText "git-allowed-signers" (
    lib.concatMapStringsSep "\n" (key: ''${email} namespaces="git" ${key}'') keys
  );

  usingGpg = gitCfg.signing.method == "gpg";
  inherit (gitCfg.signing) gpgKey;
in {
  config = lib.mkIf gitCfg.enable {
    xdg.configFile."git/allowed_signers".source = signersFile;

    programs.git = {
      inherit (gitCfg) enable;
      lfs.enable = true;

      settings = {
        user = {
          inherit email;
          name = gitCfg.userName;
          signingkey = lib.mkIf (usingGpg && gpgKey != null) gpgKey;
        };

        delta = {
          navigate = true;
          side-by-side = true;
        };

        diff = {
          colorMoved = "default";
        };

        # SSH signing (default) uses allowed_signers; GPG uses openpgp
        gpg =
          if usingGpg
          then {
            format = "openpgp";
            program = "${pkgs.gnupg}/bin/gpg";
          }
          else {
            format = "ssh";
            ssh.allowedSignersFile = toString signersFile;
          };

        init = {
          defaultBranch = "main";
        };

        merge = {
          conflictStyle = "diff3";
        };

        pull = {
          rebase = true;
        };

        github = {
          user = gitCfg.githubUsername;
        };
      };

      signing = {
        key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
        signByDefault = true;
      };
    };
  };
}
