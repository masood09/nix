{
  config,
  ...
}: let
  homelabCfg = config.homelab;
in {
  networking = {
    inherit (homelabCfg.networking) hostName computerName localHostName;
  };
}
