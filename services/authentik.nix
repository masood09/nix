{config, ...}: {
  sops.secrets = {
    "authentik-envirnoment-file" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  services.authentik = {
    enable = true;
    environmentFile = "${config.sops.secrets."authentik-envirnoment-file".path}";
    # createDatabase = false;
    settings = {
      disable_startup_analytics = true;
      avatars = "initials";
    };
    nginx = {
      enable = true;
      enableACME = true;
      host = "auth.mantannest.com";
    };
  };
}
