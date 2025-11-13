{
  networking = {
    dhcpcd.enable = false;
    useNetworkd = true;
    interfaces.enp0s6.useDHCP = true;

    hosts = {
      "100.64.0.7" = [
        "loki.monitoring.server.mantannest.com"
        "prometheus.monitoring.server.mantannest.com"
      ];
      "172.16.0.3" = [
        "proxy-server.internal.oci.mantannest.com"
      ];
      "172.16.1.3" = [
        "app-server-1.internal.oci.mantannest.com"
      ];
    };
  };
}
