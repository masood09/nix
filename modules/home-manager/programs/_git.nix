{
  config,
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  gitCfg = homelabCfg.programs.git;

  key = homelabCfg.primaryUser.sshPublicKey;
  email = gitCfg.userEmail;

  signersFile = pkgs.writeText "git-allowed-signers" ''
    ${email} namespaces="git" ${key}
  '';

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
