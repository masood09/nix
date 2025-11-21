{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
    git
    gptfdisk
    parted
  ];

  programs = {
    vim = {
      defaultEditor = true;
      enable = true;
    };
  };
}
