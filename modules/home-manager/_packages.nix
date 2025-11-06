{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      age
      coreutils
      fd
      findutils
      fzf
      gnutar
      iperf3
      ripgrep
      sops
      stow
      wget
      xz
    ];
  };
}
