{
  services = {
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      retentionTime = "30d";
      webExternalUrl = "https://prometheus.monitoring.server.mantannest.com";

      extraFlags = [
        "--web.enable-remote-write-receiver"
      ];
    };
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/prometheus2"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus2 0700 prometheus prometheus2 -"
  ];
}
