# Systemd helper generators — creates permission-fix oneshot services and
# tmpfiles rules so data directories have correct ownership before main
# services start, with optional ZFS dataset ordering.
{
  lib,
  pkgs,
}: {
  # mkPermissionService: generates the systemd services, dependencies, and tmpfiles
  # for a service that needs dataDir ownership fixed before starting.
  #
  # Arguments:
  #   name        - service name (e.g. "grafana")
  #   dataDir     - path to the data directory
  #   user        - user that owns the dataDir
  #   group       - group that owns the dataDir
  #   mainServices - list of main service names that depend on permissions (e.g. ["grafana"])
  #   zfs         - { enable, datasetServiceName } or null
  #   subDirectories - directories to create (with the same owner/mode) after
  #                    dataDir is mounted. Needed when a main service lists them
  #                    in ReadWritePaths: systemd builds the mount namespace
  #                    before ExecStart and fails with 226/NAMESPACE if any are
  #                    missing, e.g. on a fresh ZFS dataset. tmpfiles can't do
  #                    this because it may run before the dataset is mounted.
  mkPermissionService = {
    name,
    dataDir,
    user,
    group,
    mainServices,
    mode ? "0700",
    subDirectories ? [],
    zfs ? {
      enable = false;
      datasetServiceName = "zfs-dataset-${name}";
    },
  }: let
    permSvcName = "${name}-permissions";
    zfsDepService = "${zfs.datasetServiceName}.service";
  in {
    systemd = {
      services =
        lib.listToAttrs (map (svc: {
            name = svc;
            value = lib.mkMerge [
              {
                unitConfig = {
                  RequiresMountsFor = [dataDir];
                };
                requires = ["${permSvcName}.service"];
                after = ["${permSvcName}.service"];
              }
              (lib.mkIf zfs.enable {
                requires = [zfsDepService];
                after = [zfsDepService];
              })
            ];
          })
          mainServices)
        // {
          ${permSvcName} = {
            description = "Fix ${name} dataDir ownership/permissions";
            wantedBy = ["multi-user.target"];
            before = map (svc: "${svc}.service") mainServices;
            after =
              ["local-fs.target"]
              ++ lib.optionals zfs.enable [zfsDepService];
            requires =
              lib.optionals zfs.enable [zfsDepService];

            serviceConfig =
              {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = ''
                  ${pkgs.coreutils}/bin/chown ${user}:${group} ${dataDir}
                '';
              }
              // lib.optionalAttrs (subDirectories != []) {
                ExecStartPost = "${pkgs.coreutils}/bin/install -d -m ${mode} -o ${user} -g ${group} ${lib.escapeShellArgs subDirectories}";
              };
          };
        };

      tmpfiles = {
        rules = [
          "d ${dataDir} ${mode} ${user} ${group} -"
          "z ${dataDir} ${mode} ${user} ${group} -"
        ];
      };
    };
  };
}
