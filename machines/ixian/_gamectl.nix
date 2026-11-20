# gamectl — stages titles from heartbeat's game library over NFS, unpacks
# them onto the model disk as plain files, and registers them as Steam
# shortcuts so they show up in Gaming Mode.
{
  config,
  pkgs,
  ...
}: let
  # The console account (see _users.nix); it owns the install root.
  gamingUser = config.homelab.desktop.gaming.user;

  # TECH DEBT: pkgs.dwarfs at this pin fails 6 of 3670 CTest cases when
  # built from source (no substitute for this nixpkgs commit): the
  # dwarfsextract_format_test cases abort trying to write pwb/raw/xar
  # archives. Everything else - compilation and the disk-extraction
  # tests, the only code path gamectl uses - passes. Turn tests off at
  # the CMake level, not just doCheck: the upstream packaging supplies
  # gtest through nativeCheckInputs, which is also what satisfies the
  # ricepp subproject's googletest block at configure time, so
  # doCheck=false alone makes the configure phase fail. Re-test with
  # checks enabled once upstream or the pinned libarchive resolves it.
  dwarfsNoCheck = pkgs.dwarfs.overrideAttrs (final: prev: {
    doCheck = false;
    cmakeFlags =
      builtins.filter (flag: flag != "-DWITH_TESTS=ON") prev.cmakeFlags
      ++ ["-DWITH_TESTS=OFF"];
  });

  # Registers every installed title as a Steam non-Steam shortcut
  # (shortcuts.vdf, grid art, and a Proton mapping for .exe titles). The
  # header of _gamectl-steam.py has the format, the id scheme, and why it
  # only writes while Steam is stopped.
  gamectlSteam =
    pkgs.writers.writePython3 "gamectl-steam" {
      libraries = [pkgs.python3Packages.vdf];
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./_gamectl-steam.py);

  # GE-Proton is the Steam tool name of _gaming.nix's Proton-GE: nixpkgs'
  # proton-ge-bin rewrites its compatibilitytool.vdf to this fixed name, so
  # it stays valid across Proton-GE bumps.
  steamSync = "${gamectlSteam} --games /srv/models/games --tool GE-Proton --user ${gamingUser}";

  # Stage-and-unpack engine for the Questarr library (step 1 of the
  # catalog-on-the-couch flow). Library packages ship one DwarFS image
  # (files/game-root.dwarfs); the extra "dwarfs-binary"/"dwarfs-tree"
  # files are their bundled FUSE mounter and a manifest, unused here —
  # pkgs.dwarfs' dwarfsextract turns the image into plain game files in
  # well under a second per 250 MB of payload. The local copy of the
  # image itself is transient staging: deleted after a successful unpack,
  # so /srv/models holds each game exactly once, as files.
  gamectl = pkgs.writeShellScriptBin "gamectl" ''
    #!${pkgs.stdenv.shell}
    set -euo pipefail

    LIB="/srv/media-games/Linux"
    GAMES="/srv/models/games"

    usage() {
      echo "usage: gamectl list | gamectl install <Title>... | gamectl steam [--dry-run]"
    }

    cmd=''${1:-}
    shift || true

    case "$cmd" in
      steam)
        exec ${steamSync} "$@"
        ;;
      list)
        for d in "$LIB"/*/; do
          title=$(basename "$d")
          if [[ -f "$GAMES/$title/.gamectl" ]]; then
            state="installed"
          else
            state="available"
          fi
          printf '%-9s  %s\n' "$state" "$title"
        done
        ;;
      install)
        if [[ $# -lt 1 ]]; then
          usage
          exit 2
        fi
        for title in "$@"; do
          img="$LIB/$title/files/game-root.dwarfs"
          if [[ ! -f "$img" ]]; then
            echo "gamectl: no DwarFS image for '$title' (not in library?)" >&2
            exit 1
          fi
          dest="$GAMES/$title"
          if [[ -f "$dest/.gamectl" ]]; then
            echo "already installed: $title"
            continue
          fi
          size=$(stat -c %s "$img")
          free=$(df -B1 --output=avail "$GAMES" | tail -1 | tr -d ' ')
          if (( free < size * 3 )); then
            echo "gamectl: refusing '$title': needs $((size * 3)) bytes, $free free (eviction lands in a later step)" >&2
            exit 1
          fi
          echo "installing: $title ($((size / 1048576)) MiB image)"
          mkdir -p "$dest/game"
          cp "$img" "$dest/game-root.dwarfs"
          # --log-level error: the image stores heartbeat's uid/gid, which a
          # non-root installer cannot chown to, so the default warn level
          # floods one line per file on every install. Errors still surface.
          ${dwarfsNoCheck}/bin/dwarfsextract --log-level error -i "$dest/game-root.dwarfs" -o "$dest/game"
          rm "$dest/game-root.dwarfs"
          printf 'installed-at=%s\n' "$(date -Is)" > "$dest/.gamectl"
          echo "installed: $title"
        done
        ${steamSync}
        ;;
      *)
        usage
        exit 2
        ;;
    esac
  '';
in {
  config = {
    environment = {
      # The stage-and-unpack engine: gamectl plus its DwarFS unpacker.
      systemPackages = [
        gamectl
        dwarfsNoCheck
      ];
    };

    # Read-only NFS view of heartbeat's Questarr game library (server side:
    # services.nfs.server in machines/heartbeat). This is staging for the
    # pull-and-unpack flow — playable copies live on /srv/models, and
    # nothing ever writes here. The device is heartbeat's LAN address
    # rather than its headscale name on purpose: the name resolves to the
    # tailnet, where this path is currently DERP-relayed. _netdev plus
    # automount keep a down heartbeat from ever blocking the console boot.
    fileSystems = {
      "/srv/media-games" = {
        device = "10.0.20.3:/mnt/tank/media/library/games";
        mountPoint = "/srv/media-games";
        fsType = "nfs";
        options = [
          "ro"
          "noatime"
          "_netdev"
          "x-systemd.automount"
        ];
      };
    };

    systemd = {
      tmpfiles = {
        rules = [
          # gamectl's install root on the model disk. Owned by the console user
          # because Steam launches the installed titles in its session, not
          # as root, and the shortcut sync keeps its lock file here.
          "d /srv/models/games 0775 ${gamingUser} users"
        ];
      };

      user = {
        services = {
          # Syncs the Steam shortcuts at the one moment it is safe: each
          # Steam session start, before the client reads its config (a sync
          # while Steam runs is skipped, since Steam would overwrite it on
          # exit). Wanted, not required, by steam-launcher, so a failed sync
          # never keeps Steam from starting.
          gamectl-steam-sync = {
            description = "Register gamectl titles as Steam shortcuts";
            before = [
              "steam-launcher.service"
            ];
            wantedBy = [
              "steam-launcher.service"
            ];
            unitConfig = {
              ConditionUser = gamingUser;
            };
            serviceConfig = {
              Type = "oneshot";
              ExecStart = steamSync;
            };
          };
        };
      };
    };
  };
}
