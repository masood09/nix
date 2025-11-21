{homelabCfg, ...}: let
  gitCfg = homelabCfg.programs.git;
in {
  home = {
    file.".ssh/allowed_signers".text = "* ${homelabCfg.primaryUser.sshPublicKey}";
  };

  programs.git = {
    inherit (gitCfg) enable userEmail userName;
    delta.enable = true;
    lfs.enable = true;

    extraConfig = {
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
}
