{config, ...}: {
  sops.secrets = {
    "authentik-env" = {
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
  };

  services = {
    authentik = {
      enable = true;
      environmentFile = config.sops.secrets."authentik-env".path;

      settings = {
        disable_startup_analytics = true;
        avatars = "initials";
      };
    };
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/authentik"
    ];
  };
}
