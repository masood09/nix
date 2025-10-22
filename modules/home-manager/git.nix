{vars, ...}: {
  home = {
    # inspo: https://jeppesen.io/git-commit-sign-nix-home-manager-ssh/
    file.".ssh/allowed_signers".text = "* ${vars.sshPublicKeyPersonal}";
  };

  programs.git = {
    enable = true;
    userEmail = vars.userEmail;
    userName = vars.fullName;
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
