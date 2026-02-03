{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  blockyCfg = homelabCfg.services.blocky;
in {
  imports = [
    ./alloy.nix
    ./options.nix
  ];

  config = lib.mkIf blockyCfg.enable {
    services.blocky = {
      enable = true;

      settings = {
        ports = {
          dns = [
            blockyCfg.dnsPort
          ];

          http = lib.mkIf blockyCfg.metrics.enable "127.0.0.1:${toString blockyCfg.metrics.listenPort}";
        };

        upstreams.groups.default = blockyCfg.upstreamDefault;

        prometheus.enable = blockyCfg.metrics.enable;

        blocking = {
          inherit (blockyCfg) denylists allowlists clientGroupsBlock;
        };
      };
    };

    networking.firewall = {
      allowedUDPPorts = lib.mkIf blockyCfg.openFirewall [
        blockyCfg.dnsPort
      ];

      allowedTCPPorts = lib.mkIf (blockyCfg.metrics.enable && blockyCfg.metrics.openFirewall) [
        blockyCfg.metrics.listenPort
      ];
    };
  };
}
