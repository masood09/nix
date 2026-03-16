{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.matrix;
in {
  imports = [
    ./options.nix
    ./synapse.nix
    ./rtc.nix
    ./caddy.nix
  ];

  config = {
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts =
        lib.optionals cfg.synapse.enable [
          cfg.synapse.listenPort
          cfg.synapse.mas.http.web.port
          cfg.synapse.mas.http.health.port
        ]
        ++ lib.optionals cfg.rtc.enable [
          cfg.rtc.livekit.ports.tcpPort
        ];

      allowedUDPPortRanges = lib.optionals cfg.rtc.enable [
        {
          from = cfg.rtc.livekit.ports.rtcPortRangeStart;
          to = cfg.rtc.livekit.ports.rtcPortRangeEnd;
        }
      ];
    };
  };
}
