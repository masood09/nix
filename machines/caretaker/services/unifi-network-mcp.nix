{config, ...}: {
  sops.secrets = {
    "unifi-network-mcp-env" = {
      sopsFile = ./../../../secrets/caretaker.yaml;
    };
  };

  virtualisation.oci-containers.containers."unifi-network-mcp" = {
    image = "ghcr.io/sirkirby/unifi-network-mcp:0.1.4";
    autoStart = true;

    networks = ["openwebui-net"];

    environmentFiles = [
      config.sops.secrets."unifi-network-mcp-env".path
    ];
  };
}
