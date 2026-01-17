{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.zfs.datasets;

  datasetSubmodule = {name, ...}: {
    options = {
      enable = lib.mkEnableOption "Ensure this ZFS dataset exists and is mounted.";

      dataset = lib.mkOption {
        type = lib.types.str;
        example = "rpool/root/var/lib/uptime-kuma";
        description = "ZFS dataset name.";
      };

      mountpoint = lib.mkOption {
        type = lib.types.path;
        description = "Where the dataset should be mounted.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;

        default = {
          canmount = "on";
        };

        description = "ZFS properties to set (string values).";
      };

      extraCreateArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra args passed to `zfs create`.";
      };

      # Hook into other services cleanly
      requiredBy = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["uptime-kuma.service"];
        description = "Units that should require this dataset unit.";
      };

      before = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["uptime-kuma.service"];
        description = "Units that should start after this dataset unit.";
      };

      after = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["zfs-import.target" "zfs-mount.service"];
        description = "Ordering dependencies (defaults to zfs-import.target).";
      };

      wants = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["zfs-import.target" "zfs-mount.service"];
        description = "Wants dependencies (defaults to zfs-import.target).";
      };
    };
  };

  enabledDatasets =
    lib.filterAttrs (_: v: v.enable) cfg;

  mkDatasetUnit = name: dsCfg: let
    unitName = "zfs-dataset-${name}";

    effectiveProps = {canmount = "on";} // dsCfg.properties;

    propsArgs =
      lib.concatStringsSep " "
      (lib.mapAttrsToList (k: v: "-o ${lib.escapeShellArg k}=${lib.escapeShellArg v}") effectiveProps);

    extraArgs = lib.concatStringsSep " " (map lib.escapeShellArg dsCfg.extraCreateArgs);

    ds = lib.escapeShellArg dsCfg.dataset;
    mp = lib.escapeShellArg (toString dsCfg.mountpoint);
  in {
    "${unitName}" = {
      description = "Ensure ZFS dataset exists and is mounted (${dsCfg.dataset})";
      wantedBy = ["multi-user.target"];
      requiredBy = dsCfg.requiredBy;
      before = dsCfg.before ++ dsCfg.requiredBy;
      after = dsCfg.after;
      wants = dsCfg.wants;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      path = [pkgs.zfs pkgs.coreutils pkgs.util-linux];

      script = ''
        set -euo pipefail

        DATASET=${ds}
        MOUNTPOINT=${mp}

        mkdir -p "$MOUNTPOINT"

        if ! zfs list -H -o name "$DATASET" >/dev/null 2>&1; then
          echo "Creating ZFS dataset: $DATASET"
          zfs create -o mountpoint="$MOUNTPOINT" ${propsArgs} ${extraArgs} "$DATASET"
        else
          echo "ZFS dataset exists: $DATASET"
          zfs set mountpoint="$MOUNTPOINT" "$DATASET" || true
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: ''
            zfs set ${lib.escapeShellArg k}=${lib.escapeShellArg v} "$DATASET" || true
          '')
          effectiveProps)}
        fi

        if ! mountpoint -q "$MOUNTPOINT"; then
          echo "Mounting ZFS dataset: $DATASET"
          zfs mount "$DATASET" || true
        fi
      '';
    };
  };
in {
  options.homelab.zfs.datasets = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule datasetSubmodule);
    default = {};
    description = "Reusable ZFS datasets to ensure exist + mounted.";
  };

  config = lib.mkIf (enabledDatasets != {}) {
    boot.supportedFilesystems = ["zfs"];

    systemd.services =
      lib.mkMerge (lib.mapAttrsToList mkDatasetUnit enabledDatasets);
  };
}
