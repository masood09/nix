{lib, ...}: {
  options.homelab.services.blocky = {
    enable = lib.mkEnableOption "Whether to enable Blocky.";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    metrics = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      listenPort = lib.mkOption {
        type = lib.types.port;
        default = 4000;
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    dnsListen = lib.mkOption {
      type = lib.types.listOf (lib.types.oneOf [lib.types.port lib.types.str]);
      default = [53];
      description = ''
        Blocky DNS listen addresses. Each entry can be:
          - a port: 53
          - an address+port: "10.0.20.10:53"
          - wildcard: ":53"
          - IPv6: "[::1]:53"
      '';
      example = [":53" "[::]:53"];
    };

    upstreamDefault = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["10.0.20.1"];
      description = "Default upstream resolver(s) for Blocky.";
    };

    denylists = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        suspicious = [
          "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
          "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
          "https://v.firebog.net/hosts/static/w3kbl.txt"
        ];
        ads = [
          "https://adaway.org/hosts.txt"
          "https://v.firebog.net/hosts/AdguardDNS.txt"
          "https://v.firebog.net/hosts/Admiral.txt"
          "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
          "https://v.firebog.net/hosts/Easylist.txt"
          "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
          "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
          "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
        ];
        tracking = [
          "https://v.firebog.net/hosts/Easyprivacy.txt"
          "https://v.firebog.net/hosts/Prigent-Ads.txt"
          "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
          "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
          "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
        ];
        malicious = [
          "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
          "https://v.firebog.net/hosts/Prigent-Crypto.txt"
          "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
          "https://phishing.army/download/phishing_army_blocklist_extended.txt"
          "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
          "https://v.firebog.net/hosts/RPiList-Malware.txt"
          "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
          "https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts"
          "https://urlhaus.abuse.ch/downloads/hostfile/"
          "https://lists.cyberhost.uk/malware.txt"
        ];
        adult = [
          "https://raw.githubusercontent.com/chadmayfield/my-pihole-blocklists/master/lists/pi_blocklist_porn_top1m.list"
          "https://v.firebog.net/hosts/Prigent-Adult.txt"
        ];
      };
      description = "Blocky denylist groups (name -> list of URLs).";
    };

    allowlists = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        ads = [
          "https://raw.githubusercontent.com/anudeepND/whitelist/refs/heads/master/domains/whitelist.txt"
        ];
      };
      description = "Blocky allowlist groups (name -> list of URLs).";
    };

    # New: client groups mapping (CIDR -> list of group names)
    clientGroupsBlock = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        default = ["suspicious" "ads" "tracking" "malicious"];
        "10.0.70.1/24" = ["suspicious" "ads" "tracking" "malicious" "adult"];
        "10.0.200.1/24" = ["suspicious" "ads" "tracking" "malicious" "adult"];
      };
      description = "Blocky clientGroupsBlock mapping (client CIDR/name -> denylist group names).";
    };
  };
}
