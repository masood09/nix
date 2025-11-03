{
  services.prometheus.exporters.postgres = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9187;
    runAsLocalSuperUser = true;
  };
}
