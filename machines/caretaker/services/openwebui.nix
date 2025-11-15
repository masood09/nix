{
  virtualisation.oci-containers.containers."open-webui" = {
    image = "ghcr.io/open-webui/open-webui:main";
    autoStart = true;

    extraOptions = [
      "--pull=newer"
    ];

    # volumes = [
      # "/var/lib/open-webui:/app/backend/data"
    # ];

    ports = [
      "8080:3000"
    ];

    environment = {
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      # OLLAMA_BASE_URL = "http://murderbot.home.homelab.mantannest.com:11434";
    };
  };

  users = {
    users."open-webui" = {
      isSystemUser = true;
      group = "open-webui";
    };

    groups."open-webui" = {};
  };

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/open-webui"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/open-webui 0700 open-webui open-webui -"
  ];
}
