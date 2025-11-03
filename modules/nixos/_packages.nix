{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
    git
    gptfdisk
    parted
    neovim
  ];

  programs = {
    vim = {
      defaultEditor = true;
      enable = true;
    };
  };
}
