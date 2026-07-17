# Matrix sub-module — LiveKit SFU + JWT service for voice/video calls.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.matrix;
in {
  config = lib.mkIf cfg.rtc.enable {
    services = {
      "lk-jwt-service" = {
        enable = true;
        keyFile = config.sops.secrets."matrix/lk-jwt-service/keys".path;
        inherit (cfg.rtc."lk-jwt-service") port;
        livekitUrl = "wss://rtc.${cfg.rootDomain}/livekit/sfu";
      };

      livekit = {
        enable = true;
        keyFile = config.sops.secrets."matrix/lk-jwt-service/keys".path;
        openFirewall = true;

        settings = {
          bind_addresses = cfg.rtc.livekit.bindAddress;
          inherit (cfg.rtc.livekit.ports) port;

          rtc = {
            tcp_port = cfg.rtc.livekit.ports.tcpPort;
            port_range_start = cfg.rtc.livekit.ports.rtcPortRangeStart;
            port_range_end = cfg.rtc.livekit.ports.rtcPortRangeEnd;
            use_external_ip = cfg.rtc.livekit.rtcExternalIP;
          };

          room = {
            auto_create = false;
          };

          logging = {
            level = "info";
          };

          turn = {
            enabled = false;
          };
        };
      };
    };

    systemd.services."lk-jwt-service" = {
      environment = {
        LIVEKIT_FULL_ACCESS_HOMESERVERS = cfg.rootDomain;
        # The nixos-26.05 lk-jwt-service module binds LIVEKIT_JWT_BIND to
        # `:<port>` (all interfaces) and dropped the old LIVEKIT_JWT_PORT var.
        # Force localhost-only since the service sits behind the Caddy proxy.
        LIVEKIT_JWT_BIND = lib.mkForce "127.0.0.1:${toString cfg.rtc."lk-jwt-service".port}";
      };
    };
  };
}
