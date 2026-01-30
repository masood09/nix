{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.opencloud;
  podmanEnabled = homelabCfg.services.podman.enable;

  wopiWebDomain = "wopi.${cfg.webDomain}";
in {
  config = lib.mkIf (cfg.enable && podmanEnabled) {
    virtualisation.oci-containers.containers = {
      "opencloud-collabora" = {
        image = "docker.io/collabora/code:25.04.7.1.1";

        environment = {
          DONT_GEN_SSL_CERT = "YES";
          "aliasgroup1" = "https://${wopiWebDomain}";
          extra_params = "--o:ssl.enable=false --o:ssl.ssl_verification=true --o:ssl.termination=true --o:welcome.enable=false --o:net.frame_ancestors=${cfg.webDomain} --o:net.lok_allow.host[14]=${cfg.webDomain} --o:home_mode.enable=false";
        };

        environmentFiles = [
          config.sops.secrets."opencloud-collabora.env".path
        ];

        ports = [
          "127.0.0.1:${toString cfg.collabora.port}:9980/tcp"
        ];

        log-driver = "journald";
        entrypoint = "/bin/bash";

        cmd = [
          "-lc"
          "coolconfig generate-proof-key && exec /start-collabora-online.sh"
        ];

        extraOptions = [
          "--network=opencloud_opencloud-net"
          "--network-alias=collabora"
          "--cap-add=MKNOD"
        ];
      };
    };

    systemd = {
      targets = {
        "podman-compose-opencloud-root" = {
          unitConfig = {
            Description = "Root target for OpenCloud.";
          };

          wantedBy = ["multi-user.target"];

          after = [
            "zfs-dataset-opencloud-root.service"
            "zfs-dataset-opencloud-etc.service"
            "zfs-dataset-opencloud-idm.service"
            "zfs-dataset-opencloud-nats.service"
            "zfs-dataset-opencloud-search.service"
            "zfs-dataset-opencloud-storage.service"
            "zfs-dataset-opencloud-storage-metadata.service"
            "zfs-dataset-opencloud-storage-users.service"
            "opencloud-permissions.service"
          ];

          requires = [
            "zfs-dataset-opencloud-root.service"
            "zfs-dataset-opencloud-etc.service"
            "zfs-dataset-opencloud-idm.service"
            "zfs-dataset-opencloud-nats.service"
            "zfs-dataset-opencloud-search.service"
            "zfs-dataset-opencloud-storage.service"
            "zfs-dataset-opencloud-storage-metadata.service"
            "zfs-dataset-opencloud-storage-users.service"
            "opencloud-permissions.service"
          ];
        };
      };

      services = {
        "podman-network-opencloud_opencloud-net" = {
          path = [pkgs.podman];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "podman network rm -f opencloud_opencloud-net";
          };

          script = ''
            podman network inspect opencloud_opencloud-net || podman network create opencloud_opencloud-net
          '';

          partOf = ["podman-compose-opencloud-root.target"];
          wantedBy = ["podman-compose-opencloud-root.target"];
        };

        "podman-opencloud-collabora" = {
          serviceConfig = {
            Restart = lib.mkOverride 90 "always";
          };

          after = [
            "podman-network-opencloud_opencloud-net.service"
            "zfs-dataset-opencloud-root.service"
            "zfs-dataset-opencloud-etc.service"
            "zfs-dataset-opencloud-idm.service"
            "zfs-dataset-opencloud-nats.service"
            "zfs-dataset-opencloud-search.service"
            "zfs-dataset-opencloud-storage.service"
            "zfs-dataset-opencloud-storage-metadata.service"
            "zfs-dataset-opencloud-storage-users.service"
            "opencloud-permissions.service"
          ];

          requires = [
            "podman-network-opencloud_opencloud-net.service"
            "zfs-dataset-opencloud-root.service"
            "zfs-dataset-opencloud-etc.service"
            "zfs-dataset-opencloud-idm.service"
            "zfs-dataset-opencloud-nats.service"
            "zfs-dataset-opencloud-search.service"
            "zfs-dataset-opencloud-storage.service"
            "zfs-dataset-opencloud-storage-metadata.service"
            "zfs-dataset-opencloud-storage-users.service"
            "opencloud-permissions.service"
          ];

          partOf = [
            "podman-compose-opencloud-root.target"
          ];

          wantedBy = [
            "podman-compose-opencloud-root.target"
          ];
        };
      };
    };
  };
}
