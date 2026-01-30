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
  collaboraWebDomain = "collabora.${cfg.webDomain}";

  waitForCollabora = pkgs.writeShellScript "wait-for-podman-opencloud-collabora" ''
    set -euo pipefail
    url="http://127.0.0.1:${toString cfg.collabora.port}/hosting/discovery"
    echo "Waiting for Collabora: $url"

    for i in $(seq 1 120); do
      if ${pkgs.curl}/bin/curl -fsS --max-time 2 "$url" >/dev/null; then
        echo "Collabora is up"
        exit 0
      fi
      sleep 1
    done

    echo "Timed out waiting for Collabora"
    exit 1
  '';
in {
  config = lib.mkIf (cfg.enable && podmanEnabled) {
    virtualisation.oci-containers.containers = {
      "opencloud-opencloud" = {
        # renovate: datasource=docker depName=docker.io/opencloudeu/opencloud
        image = "docker.io/opencloudeu/opencloud:4.0.1";

        environment = {
          "COLLABORA_DOMAIN" = collaboraWebDomain;
          "FRONTEND_APP_HANDLER_SECURE_VIEW_APP_ADDR" = "eu.opencloud.api.collaboration";
          "FRONTEND_ARCHIVER_MAX_SIZE" = "10000000000";
          "FRONTEND_CHECK_FOR_UPDATES" = "false";
          "GATEWAY_GRPC_ADDR" = "0.0.0.0:9142";
          "GRAPH_ASSIGN_DEFAULT_USER_ROLE" = "false";
          "GRAPH_AVAILABLE_ROLES" = "b1e2218d-eef8-4d4c-b82d-0f1a1b48f3b5,a8d5fe5e-96e3-418d-825b-534dbdf22b99,fb6c3e19-e378-47e5-b277-9732f9de6e21,58c63c02-1d89-4572-916a-870abc5a1b7d,2d00ce52-1fc2-4dbc-8b95-a73b73395f5a,1c996275-f1c9-4e71-abdf-a42f6495e960,312c0871-5ef7-4b3a-85b6-0e4074c64049,aa97fe03-7980-45ac-9e50-b325749fd7e6";
          "GRAPH_USERNAME_MATCH" = "none";
          "IDM_CREATE_DEMO_USERS" = "false";
          "IDP_DOMAIN" = cfg.idpDomain;
          "NATS_NATS_HOST" = "0.0.0.0";
          "OC_ADD_RUN_SERVICES" = "notifications";
          "OC_DEFAULT_LANGUAGE" = "en";
          "OC_EXCLUDE_RUN_SERVICES" = "idp";
          "OC_INSECURE" = "true";
          "OC_LOG_COLOR" = "false";
          "OC_LOG_LEVEL" = cfg.logLevel;
          "OC_LOG_PRETTY" = "false";
          "OC_OIDC_ISSUER" = "https://${cfg.idpDomain}/application/o/opencloud/";
          "OC_PASSWORD_POLICY_DISABLED" = "false";
          "OC_PASSWORD_POLICY_MIN_CHARACTERS" = "8";
          "OC_PASSWORD_POLICY_MIN_DIGITS" = "1";
          "OC_PASSWORD_POLICY_MIN_LOWERCASE_CHARACTERS" = "1";
          "OC_PASSWORD_POLICY_MIN_SPECIAL_CHARACTERS" = "1";
          "OC_PASSWORD_POLICY_MIN_UPPERCASE_CHARACTERS" = "1";
          "OC_SHARING_PUBLIC_SHARE_MUST_HAVE_PASSWORD" = "true";
          "OC_SHARING_PUBLIC_WRITEABLE_SHARE_MUST_HAVE_PASSWORD" = "false";
          "OC_URL" = "https://${cfg.webDomain}";
          "OIDC_REDIRECT_URI" = "https://${cfg.webDomain}";
          "PROXY_AUTOPROVISION_ACCOUNTS" = "true";
          "PROXY_AUTOPROVISION_CLAIM_USERNAME" = "preferred_username";
          "PROXY_CSP_CONFIG_FILE_LOCATION" = "/etc/opencloud/csp.yaml";
          "PROXY_ENABLE_BASIC_AUTH" = "false";
          "PROXY_HTTP_ADDR" = "0.0.0.0:9200";
          "PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD" = "none";
          "PROXY_OIDC_REWRITE_WELLKNOWN" = "true";
          "PROXY_OIDC_SKIP_VERIFICATION" = "false";
          "PROXY_ROLE_ASSIGNMENT_DRIVER" = "oidc";
          "PROXY_ROLE_ASSIGNMENT_OIDC_CLAIM" = "groups";
          "PROXY_TLS" = "false";
          "PROXY_USER_OIDC_CLAIM" = "preferred_username";
          "WEB_OIDC_SCOPE" = "openid profile email groups offline_access";
        };

        environmentFiles = [
          config.sops.secrets."opencloud-opencloud.env".path
        ];

        volumes = [
          "/var/lib/opencloud:/var/lib/opencloud:rw"
          "/var/lib/opencloud/etc:/etc/opencloud:rw"
        ];

        ports = [
          "127.0.0.1:${toString cfg.port}:9200/tcp"
        ];

        entrypoint = "/bin/bash";
        cmd = ["-c" "opencloud init || true; opencloud server"];
        user = "${toString cfg.userId}:${toString cfg.groupId}";
        log-driver = "journald";

        extraOptions = [
          "--network-alias=opencloud"
          "--network=opencloud_opencloud-net"
        ];
      };

      "opencloud-wopi" = {
        # renovate: datasource=docker depName=docker.io/opencloudeu/opencloud
        image = "docker.io/opencloudeu/opencloud:4.0.1";

        environment = {
          "COLLABORATION_APP_ADDR" = "https://${collaboraWebDomain}";
          "COLLABORATION_APP_ICON" = "https://${collaboraWebDomain}/favicon.ico";
          "COLLABORATION_APP_INSECURE" = "true";
          "COLLABORATION_APP_NAME" = "CollaboraOnline";
          "COLLABORATION_APP_PRODUCT" = "Collabora";
          "COLLABORATION_CS3API_DATAGATEWAY_INSECURE" = "true";
          "COLLABORATION_GRPC_ADDR" = "0.0.0.0:9301";
          "COLLABORATION_HTTP_ADDR" = "0.0.0.0:9300";
          "COLLABORATION_LOG_LEVEL" = "${cfg.logLevel}";
          "COLLABORATION_WOPI_SRC" = "https://${wopiWebDomain}";
          "MICRO_REGISTRY" = "nats-js-kv";
          "MICRO_REGISTRY_ADDRESS" = "opencloud:9233";
          "OC_URL" = "https://${cfg.webDomain}";
        };

        volumes = [
          "${cfg.dataDir}:/var/lib/opencloud:rw"
          "${cfg.dataDir}/etc:/etc/opencloud:rw"
        ];

        ports = [
          "127.0.0.1:${toString cfg.wopi.port}:9300/tcp"
        ];

        entrypoint = "/bin/bash";
        cmd = ["-c" "opencloud collaboration server"];

        dependsOn = [
          "opencloud-opencloud"
          "opencloud-collabora"
        ];

        user = "${toString cfg.userId}:${toString cfg.groupId}";
        log-driver = "journald";

        extraOptions = [
          "--network-alias=wopi"
          "--network=opencloud_opencloud-net"
        ];
      };

      "opencloud-collabora" = {
        # renovate: datasource=docker depName=docker.io/collabora/code
        image = "docker.io/collabora/code:25.04.8.2.1";

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

        "podman-opencloud-opencloud" = {
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

        "podman-opencloud-wopi" = {
          serviceConfig = {
            Restart = lib.mkOverride 90 "always";

            ExecStartPre = [waitForCollabora];
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

        "podman-opencloud-collabora" = {
          serviceConfig = {
            Restart = lib.mkOverride 90 "always";
          };

          after = [
            "podman-network-opencloud_opencloud-net.service"
          ];

          requires = [
            "podman-network-opencloud_opencloud-net.service"
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
