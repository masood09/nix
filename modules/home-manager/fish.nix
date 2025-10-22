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
          inherit (pkgs.fishPlugins.tide) src;
        }
        {
          name = "fzf";
          inherit (pkgs.fishPlugins.fzf) src;
        }
      ];
    };
  };
}
