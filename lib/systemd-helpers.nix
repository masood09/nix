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
  mkPermissionService = {
    name,
    dataDir,
    user,
    group,
    mainServices,
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

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = ''
                ${pkgs.coreutils}/bin/chown ${user}:${group} ${dataDir}
              '';
            };
          };
        };

      tmpfiles.rules = [
        "d ${dataDir} 0700 ${user} ${group} -"
        "z ${dataDir} 0700 ${user} ${group} -"
      ];
    };
  };
}
