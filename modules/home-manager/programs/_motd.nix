{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.motd;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

  motd = pkgs.writeShellScriptBin "motd" ''
    #!/usr/bin/env bash

    # Be resilient: this should never break login.
    set +e

    RED="\e[31m"
    GREEN="\e[32m"
    BOLD="\e[1m"
    ENDCOLOR="\e[0m"

    have() { command -v "$1" >/dev/null 2>&1; }

    # OS release name (NixOS has /etc/os-release)
    PRETTY_NAME=""
    if [ -r /etc/os-release ]; then
      # shellcheck disable=SC1091
      . /etc/os-release
      PRETTY_NAME="$PRETTY_NAME"
    fi

    # Load averages (Linux)
    LOAD1="n/a"; LOAD5="n/a"; LOAD15="n/a"
    if [ -r /proc/loadavg ]; then
      LOAD1="$(awk '{print $1}' /proc/loadavg 2>/dev/null)"
      LOAD5="$(awk '{print $2}' /proc/loadavg 2>/dev/null)"
      LOAD15="$(awk '{print $3}' /proc/loadavg 2>/dev/null)"
    elif have uptime; then
      # Best-effort fallback (varies across OS)
      LOAD1="$(uptime 2>/dev/null | sed -n 's/.*load averages\{0,1\}[: ] *\([0-9.]*\).*/\1/p')"
      LOAD5="$(uptime 2>/dev/null | sed -n 's/.*load averages\{0,1\}[: ] *[0-9.]*[, ] *\([0-9.]*\).*/\1/p')"
      LOAD15="$(uptime 2>/dev/null | sed -n 's/.*load averages\{0,1\}[: ] *[0-9.]*[, ] *[0-9.]*[, ] *\([0-9.]*\).*/\1/p')"
      LOAD1="''${LOAD1:-n/a}"; LOAD5="''${LOAD5:-n/a}"; LOAD15="''${LOAD15:-n/a}"
    fi

    # Memory (Linux)
    MEMORY="n/a"
    if have free; then
      MEMORY="$(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100 / $2 }' 2>/dev/null)"
      MEMORY="''${MEMORY:-n/a}"
    fi

    # Uptime (Linux /proc) fallback to `uptime -p` if available
    UPTIME_FMT="n/a"
    if [ -r /proc/uptime ]; then
      uptime_s="$(cut -f1 -d. /proc/uptime 2>/dev/null)"
      if [ -n "$uptime_s" ]; then
        upDays=$((uptime_s/60/60/24))
        upHours=$((uptime_s/60/60%24))
        upMins=$((uptime_s/60%60))
        upSecs=$((uptime_s%60))
        UPTIME_FMT="$upDays days $upHours hours $upMins minutes $upSecs seconds"
      fi
    elif have uptime; then
      UPTIME_FMT="$(uptime -p 2>/dev/null)"
      UPTIME_FMT="''${UPTIME_FMT:-n/a}"
    fi

    # time of day
    HOUR="$(date +"%H" 2>/dev/null)"
    TIME="day"
    if [ -n "$HOUR" ]; then
      if [ "$HOUR" -lt 12 ] && [ "$HOUR" -ge 0 ]; then
        TIME="morning"
      elif [ "$HOUR" -lt 17 ] && [ "$HOUR" -ge 12 ]; then
        TIME="afternoon"
      else
        TIME="evening"
      fi
    fi

    HOST="$(hostname 2>/dev/null || echo unknown-host)"
    KERNEL="$(uname -rs 2>/dev/null || echo unknown-kernel)"

    # Header
    if have figlet; then
      if have lolcat; then
        figlet "$HOST" | lolcat -f
      else
        figlet "$HOST"
      fi
    else
      printf "%b%s%b\n" "$BOLD" "$HOST" "$ENDCOLOR"
    fi

    # Purpose/role
    if [ -n "${homelabCfg.purpose}" ]; then
      printf "%b    %-20s%b %s\n" "$BOLD" "Role:" "$ENDCOLOR" "${homelabCfg.purpose}"
      printf "\n"
    fi

    # IPs
    ${
      lib.strings.concatStrings (
        lib.lists.forEach cfg.networkInterfaces (iface: ''
          if have ip; then
            ip4="$(ip -4 addr show ${lib.escapeShellArg iface} 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)"
            if [ -n "$ip4" ]; then
              printf "%b  * %-20s%b %s\n" "$BOLD" "IPv4 ${iface}" "$ENDCOLOR" "$ip4"
            else
              printf "%b  * %-20s%b %s\n" "$BOLD" "IPv4 ${iface}" "$ENDCOLOR" "n/a"
            fi
          fi
        '')
      )
    }

    [ -n "$PRETTY_NAME" ] && printf "%b  * %-20s%b %s\n" "$BOLD" "Release" "$ENDCOLOR" "$PRETTY_NAME"
    printf "%b  * %-20s%b %s\n" "$BOLD" "Kernel" "$ENDCOLOR" "$KERNEL"

    if [ -f /var/run/reboot-required ]; then
      printf "%b  * %-20s%b %s\n" "$RED" "Notice" "$ENDCOLOR" "A reboot is required"
    fi

    printf "\n"
    printf "%b  * %-20s%b %s\n" "$BOLD" "CPU usage" "$ENDCOLOR" "$LOAD1, $LOAD5, $LOAD15 (1, 5, 15 min)"
    printf "%b  * %-20s%b %s\n" "$BOLD" "Memory" "$ENDCOLOR" "$MEMORY"
    printf "%b  * %-20s%b %s\n" "$BOLD" "System uptime" "$ENDCOLOR" "$UPTIME_FMT"
    printf "\n"

    # ZFS (optional)
    if ${
      if homelabCfg.isRootZFS
      then "true"
      else "false"
    } && have zpool; then
      printf "%bZpool status:%b\n" "$BOLD" "$ENDCOLOR"
      zpool status -x 2>/dev/null | sed -e 's/^/  /'
      printf "\n"
      printf "%bZpool usage:%b\n" "$BOLD" "$ENDCOLOR"
      zpool list -Ho name,cap,size 2>/dev/null \
        | awk '{ printf("%-10s%+3s used out of %+5s\n", $1, $2, $3); }' \
        | sed -e 's/^/  /'
      printf "\n"
    fi
  '';
in {
  config = lib.mkIf cfg.enable {
    home.packages = [
      motd
      pkgs.figlet
      pkgs.lolcat
    ];

    # Your _zsh.nix already returns early for TERM=dumb and non-interactive.
    # So we only need a lightweight call here, ordered after that guard.
    programs.zsh.initContent = lib.mkIf zshEnabled (lib.mkOrder cfg.zshInitOrder ''
      [[ -o interactive ]] && command -v motd >/dev/null 2>&1 && motd
    '');
  };
}
