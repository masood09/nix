{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  blockyCfg = homelabCfg.services.blocky;

  portFromListen = v:
    if builtins.isInt v
    then v
    else let
      m = builtins.match ".*:([0-9]+)$" v;
    in
      if m == null
      then lib.toInt v
      else lib.toInt (builtins.elemAt m 0);

  dnsPorts =
    lib.unique (map portFromListen blockyCfg.dnsListen);
in {
  imports = [
    ./alloy.nix
    ./options.nix
    ./unbound.nix
  ];

  config = lib.mkIf blockyCfg.enable {
    services.blocky = {
      enable = true;

      settings = {
        ports = {
          dns = blockyCfg.dnsListen;

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
      allowedUDPPorts = lib.mkIf blockyCfg.openFirewall dnsPorts;
      allowedTCPPorts = lib.mkIf blockyCfg.openFirewall (
        dnsPorts
        ++ lib.optional (blockyCfg.metrics.enable && blockyCfg.metrics.openFirewall)
        blockyCfg.metrics.listenPort
      );
    };
  };
}
