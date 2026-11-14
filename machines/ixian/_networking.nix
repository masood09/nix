# Machine networking. NetworkManager (enabled through
# homelab.networking.wireless_enable in _config.nix, for Steam Gaming Mode)
# brings up the onboard 2.5GbE NIC with DHCP, and the UniFi controller's DHCP
# reservation pins the address.
{
  config = {
    boot = {
      initrd = {
        systemd = {
          network = {
            networks = {
              # DHCP for the initrd SSH server (remote LUKS unlock). Declared here
              # rather than through the `ip=dhcp` kernel parameter: only declared
              # networks get KeepConfiguration=false from the shared
              # flushBeforeStage2, and a generated one keeps its lease into stage
              # 2. NetworkManager then adopts the address as external and never
              # renews it, so ixian drops off the network when the lease expires.
              "10-initrd-lan" = {
                matchConfig = {
                  Name = "enp5s0";
                };
                networkConfig = {
                  DHCP = "ipv4";
                };
              };
            };
          };
        };
      };
    };
  };
}
