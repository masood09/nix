{
  services.prometheus.exporters.postgres = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9187;
    runAsLocalSuperUser = true;
  };
}
