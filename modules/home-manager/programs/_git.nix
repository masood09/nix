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
in {
  config = lib.mkIf gitCfg.enable {
    xdg.configFile."git/allowed_signers".source = signersFile;

    programs.git = {
      inherit (gitCfg) enable;
      lfs.enable = true;

      settings = {
        user = {
          email = email;
          name = gitCfg.userName;
        };

        delta = {
          navigate = true;
          side-by-side = true;
        };

        diff = {
          colorMoved = "default";
        };

        gpg = {
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
      };

      signing = {
        key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
        signByDefault = true;
      };
    };
  };
}
