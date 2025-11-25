{lib, ...}: {
  options.homelab.services.minio = {
    enable = lib.mkEnableOption "Whether to enable Minio Object Storage.";
    browser = lib.mkEnableOption "Enable or disable access to web UI.";

    certificatesDir = lib.mkOption {
      default = "/var/lib/minio/certs";
      type = lib.types.path;
      description = "The directory where TLS certificates are stored.";
    };

    configDir = lib.mkOption {
      default = "/var/lib/minio/config";
      type = lib.types.path;
      description = "The config directory, for the access keys and other settings.";
    };

    consoleAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
      description = "IP address of the web UI (console).";
    };

    consolePort = lib.mkOption {
      default = 9001;
      type = lib.types.port;
      description = "The port of the web UI (console).";
    };

    dataDir = lib.mkOption {
      default = [ "/var/lib/minio/data" ];
      type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
      description = ''
        The list of data directories or nodes for storing the objects. Use one path for regular operation and the minimum of 4 endpoints for Erasure Code mode.
      '';
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
      description = "IP address of the server.";
    };

    listenPort = lib.mkOption {
      default = 9000;
      type = lib.types.port;
      description = "The port of the server.";
    };

    openFirewall = lib.mkEnableOption "Open ports in the firewall for MiniIO console and web";

    rootCredentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File containing the MINIO_ROOT_USER, default is "minioadmin", and
        MINIO_ROOT_PASSWORD (length >= 8), default is "minioadmin"; in the format of
        an EnvironmentFile=, as described by {manpage}`systemd.exec(5)`.
      '';
      example = "/etc/nixos/minio-root-credentials";
    };

    region = lib.mkOption {
      default = "homelab";
      type = lib.types.str;
      description = ''
        The physical location of the server. By default it is set to us-east-1, which is same as AWS S3's and Minio's default region.
      '';
    };
  };
}
