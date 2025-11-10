{
  services = {
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      webExternalUrl = "https://prometheus.monitoring.server.mantannest.com";

      extraFlags = [
        "--web.enable-remote-write-receiver"
      ];
    };
  };
}
