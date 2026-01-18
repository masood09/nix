{
  homelabCfg,
  lib,
  ...
}: let
  gitCfg = homelabCfg.programs.git;
in {
  config = lib.mkIf gitCfg.enable {
    home = {
      file.".ssh/allowed_signers".text = "* ${homelabCfg.primaryUser.sshPublicKey}";
    };

    programs.git = {
      inherit (gitCfg) enable;
      lfs.enable = true;

      settings = {
        user = {
          email = gitCfg.userEmail;
          name = gitCfg.userName;
        };

        delta = {
          navigate = true;
          side-by-side = true;
        };

        diff = {
          colorMoved = "default";
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
    };
  };
}
