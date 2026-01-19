{
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_secrets.nix

    ./../../modules/nixos
    ./../../modules/home-manager
  ];

  homelab.disks = {
    root = [
      "ata-Patriot_P220_128GB_P220HHBB241107006862"
      "ata-Patriot_P220_128GB_P220HHBB241107006844"
    ];

    fast = [
      "nvme-FIKWOT_FN501_Pro_2TB_AA234920273"
      "nvme-FIKWOT_FN501_Pro_2TB_AA234910104"
    ];

    data = [
      "ata-TOSHIBA_MG08ACA14TE_6180A0MUFVJG"
      "ata-TOSHIBA_MG08ACA14TE_6180A0KRFVJG"
      "ata-TOSHIBA_MG08ACA14TE_6180A0Y8FVJG"
      "ata-TOSHIBA_MG08ACA14TE_6180A0LKFVJG"
      "ata-TOSHIBA_MG08ACA14TE_6180A0Y6FVJG"
      "ata-TOSHIBA_MG08ACA14TE_6180A126FVJG"
    ];
  };

  fileSystems = {
    "/".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/nix/persist".neededForBoot = true;
    "/var/backup".neededForBoot = true;
    "/var/lib/nixos".neededForBoot = true;
    "/var/log".neededForBoot = true;
  };
}
