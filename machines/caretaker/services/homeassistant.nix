{config, ...}: {
  virtualisation.oci-containers.containers.homeassistant = {
    image = "homeassistant/home-assistant:stable";
    autoStart = true;

    extraOptions = [
      "--pull=newer"
      "--cap-add=CAP_NET_RAW"
    ];

    volumes = [
      "/var/lib/homeassistant:/config"
    ];

    ports = [
      "127.0.0.1:8123:8123"
      "127.0.0.1:8124:80"
    ];

    environment = {
      TZ = config.time.timeZone;
      PUID = toString config.users.users.homeassistant.uid;
      PGID = toString config.users.groups.homeassistant.gid;
    };
  };

  users = {
    users.homeassistant = {
      isSystemUser = true;
      group = "homeassistant";
    };

    groups.homeassistant = {};
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/homeassistant"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/homeassistant 0700 homeassistant homeassistant -"
  ];
}
