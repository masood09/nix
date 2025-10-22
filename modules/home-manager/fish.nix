{pkgs, ...}: {
  programs = {
    fish = {
      enable = true;

      shellAliases = {
        cat = "bat";
        cd = "z";
        em = "emacsclient -c -n -a ''";
        ls = "eza --color=always --git --icons=always";
      };

      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';

      plugins = [
        {
          name = "tide";
          src = pkgs.fishPlugins.tide.src;
        }
        {
          name = "fzf";
          src = pkgs.fishPlugins.fzf.src;
        }
      ];
    };
  };
}
