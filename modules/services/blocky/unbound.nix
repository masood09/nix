{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  blockyCfg = homelabCfg.services.blocky;
  cfg = blockyCfg.unbound;
in {
  config = lib.mkIf (blockyCfg.enable && cfg.enable) {
    services.unbound = {
      enable = true;
      resolveLocalQueries = false;

      settings = {
        server = {
          inherit (cfg) port;
          interface = ["127.0.0.1"];
          access-control = ["127.0.0.1 allow"];

          # Based on recommended settings in https://docs.pi-hole.net/guides/dns/unbound/#configure-unbound
          harden-glue = true;
          harden-dnssec-stripped = true;
          use-caps-for-id = false;
          prefetch = true;
          edns-buffer-size = 1232;

          # Custom settings
          hide-identity = true;
          hide-version = true;
        };

        forward-zone = [
          {
            name = cfg.localDomain;
            forward-addr = [
              "10.0.20.1"
            ];
          }
        ];
      };
    };

    users.users = {
      "${config.services.unbound.user}".uid = cfg.userId;
    };

    users.groups = {
      "${config.services.unbound.group}".gid = cfg.groupId;
    };
  };
}
