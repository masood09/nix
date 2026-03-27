# Tmux — terminal multiplexer.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  fishEnabled = homelabCfg.programs.fish.enable or false;
in {
  programs = {
    tmux = {
      inherit (homelabCfg.programs.tmux) enable;

      # Use fish inside tmux sessions when fish is enabled, matching kitty's
      # shell setting so the experience is consistent.
      shell = lib.mkIf fishEnabled "${pkgs.fish}/bin/fish";
    };
  };
}
