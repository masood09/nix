{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;

  # Any datasets with enable = true?
  anyManagedDatasets = (lib.attrNames (lib.filterAttrs (_: v: v.enable or false) homelabCfg.zfs.datasets)) != [];

  enableZFS = (homelabCfg.isRootZFS or false) || anyManagedDatasets;

  webhookFile = config.sops.secrets."zed/discord-zfs-webhook".path;

  zedDiscord = pkgs.writeShellScript "zed-discord" ''
      set -euo pipefail

      subject=""
      while getopts "s:" opt; do
        case "$opt" in
          s) subject="$OPTARG" ;;
        esac
      done
      shift $((OPTIND-1))

      webhook="$(cat ${webhookFile})"
      body="$(cat)"

      payload="$(
        SUBJECT="$subject" BODY="$body" \
        ${pkgs.python3}/bin/python - <<'PY'
    import json, os
    subject = os.environ.get("SUBJECT", "")
    body = os.environ.get("BODY", "")
    body = body[:1800]  # Discord limit 2000; leave room for formatting
    content = f"**{subject}**\n```{body}```"
    print(json.dumps({"content": content}))
    PY
      )"

      ${pkgs.curl}/bin/curl -fsS \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$webhook" >/dev/null
  '';
in {
  config = lib.mkIf enableZFS {
    services = lib.mkIf (homelabCfg.isRootZFS || anyManagedDatasets) {
      zfs.zed = {
        enableMail = false;

        settings = {
          ZED_EMAIL_ADDR = ["root"];

          # Run our webhook poster instead of a real mailer
          ZED_EMAIL_PROG = "${zedDiscord}";
          ZED_EMAIL_OPTS = "-s '@SUBJECT@'"; # ZED passes subject via -s

          # Optional: make notifications less spammy / more verbose
          ZED_NOTIFY_INTERVAL_SECS = 3600; # throttle similar events
          ZED_NOTIFY_VERBOSE = true; # include scrub successes etc.
        };
      };
    };
  };
}
