{
  imports = [
    ./../../../services/_acme.nix
  ];

  security.acme = {
    certs = {
      "grafana.mantannest.com".domain = "grafana.mantannest.com";
      "loki.monitoring.server.mantannest.com".domain = "loki.monitoring.server.mantannest.com";
      "prometheus.monitoring.server.mantannest.com".domain = "prometheus.monitoring.server.mantannest.com";
    };
  };
}
