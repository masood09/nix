# logcli — Grafana Loki query CLI, wrapped to tunnel into the log server.
#
# Loki binds to 127.0.0.1 on the server (see modules/services/loki), so the
# wrapper opens an SSH local port forward before handing off to the real
# logcli with LOKI_ADDR pointed at the local end. No credentials are needed:
# the tunnel rides existing key-based SSH and bypasses Caddy's basic auth.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.logcli;

  logcliBin = lib.getExe' pkgs.grafana-loki "logcli";

  logcli = pkgs.writeShellApplication {
    name = "logcli";

    runtimeInputs = [
      pkgs.openssh
    ];

    text = ''
      # Backgrounded forward, reused across invocations. ExitOnForwardFailure
      # makes a second attempt fail rather than silently running without a
      # tunnel, so a non-zero exit here means one is already up.
      ssh -f -N -o ExitOnForwardFailure=yes \
        -L ${toString cfg.localPort}:127.0.0.1:${toString cfg.remotePort} \
        ${cfg.remoteHost} 2>/dev/null || true

      export LOKI_ADDR="http://127.0.0.1:${toString cfg.localPort}"

      exec ${logcliBin} "$@"
    '';
  };
in {
  home = {
    packages = lib.mkIf cfg.enable [
      logcli
    ];
  };
}
