{
  config.sops.secrets = {
    "alloy/.env" = {
      restartUnits = ["alloy.service"];
    };

    "user/password" = {
      sopsFile = ./secrets.sops.yaml;
      neededForUsers = true;
    };

    "zed/discord-zfs-webhook" = {};
  };
}
