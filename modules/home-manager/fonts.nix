{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      julia-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.symbols-only
      nerd-fonts.hack
    ];
  };
}
