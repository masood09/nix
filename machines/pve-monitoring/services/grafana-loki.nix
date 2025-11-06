{config, ...}: {
  sops.secrets = {
    "loki-config" = {
      owner = "loki";
      sopsFile = ./../../../secrets/pve-monitoring.yaml;
    };
  };

  services = {
    loki = {
      enable = true;

      configFile = config.sops.secrets."loki-config".path;
    };
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/loki"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/loki 0700 loki loki -"
  ];
}
