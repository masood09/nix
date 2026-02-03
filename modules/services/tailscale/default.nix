{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.tailscale;
in {
  imports = [
    ./options.nix
  ];

  config = {
    homelab.zfs.datasets.tailscale = lib.mkIf (cfg.enable && cfg.zfs.enable) {
      inherit (cfg.zfs) dataset properties;

      enable = true;
      mountpoint = cfg.dataDir;
      requiredBy = ["tailscaled.service"];
    };

    services = lib.mkIf cfg.enable {
      tailscale = {
        inherit (cfg) enable;

        authKeyFile = config.sops.secrets."headscale-preauth.key".path;

        extraUpFlags = [
          "--login-server=${cfg.loginServer}"
        ];
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        tailscaled = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir];
            };
          }

          (lib.mkIf cfg.zfs.enable {
            requires = ["zfs-dataset-tailscale.service"];
            after = ["zfs-dataset-tailscale.service"];
          })
        ];

        tailscaled-permissions = {
          description = "Fix Tailscale dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = ["tailscaled.service"];
          after =
            ["local-fs.target"]
            ++ lib.optionals cfg.zfs.enable ["zfs-dataset-tailscale.service"];
          requires =
            lib.optionals cfg.zfs.enable ["zfs-dataset-tailscale.service"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown -R root:root ${cfg.dataDir}
            '';
          };
        };
      };
    };

    environment.persistence."/nix/persist" =
      lib.mkIf (
        !homelabCfg.isRootZFS
        && cfg.enable
        && !cfg.zfs.enable
      ) {
        directories = [
          cfg.dataDir
        ];
      };
  };
}
