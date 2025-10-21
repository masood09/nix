{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.symbols-only
    ];
  };
}
