{
  config,
  pkgs,
  ...
}: {
  virtualisation.podman.enable = true;

  systemd.services.podman-create-openwebui-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "podman-unifi-network-mcp.service" ];
    script = ''
      ${pkgs.podman}/bin/podman network exists openwebui-net || \
        ${pkgs.podman}/bin/podman network create openwebui-net 
    '';
  };
}
