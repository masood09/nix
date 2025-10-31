{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    "authentik-envirnoment-file" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  services= {
    authentik = {
      enable = true;
      environmentFile = "${config.sops.secrets."authentik-envirnoment-file".path}";
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

    postgresql = {
      package = pkgs.postgresql_16;
    };
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/postgresql"
    ];
  };
}
