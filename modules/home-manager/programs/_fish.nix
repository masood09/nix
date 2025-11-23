{
  homelabCfg,
  pkgs,
  ...
}: {
  programs = {
    fish = {
      inherit (homelabCfg.programs.fish) enable;

      interactiveShellInit = ''
        # Disable greeting
        set fish_greeting
      '';

      plugins = [
        {
          name = "fzf";
          inherit (pkgs.fishPlugins.fzf) src;
        }
      ];
    };
  };
}
