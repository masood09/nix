"""Gamectl's Steam integration: a grid tile for every library title, plus
the command Steam runs when a tile's Play button is pressed.

Subcommands (invoked by the gamectl wrapper, which passes --library,
--games, --user, --wrapper and --proton):
  steam [--dry-run]   rewrite Steam's per-user shortcuts.vdf so every
                      title in the read-only library is a grid tile
  launch <Title>      a tile's actual command: install if needed, then
                      exec the game (through GE-Proton for .exe titles)

Re-executes itself as --user (the console account) when started by
anyone else, since Steam's files and the games' prefixes belong to it.

Design, continued from the version that first made tiles appear:
  * The catalogue is the library mount itself (a title is any directory
    with files/game-root.dwarfs), not the installed set: tiles exist
    before a game is installed, and Play does the copy-and-unpack.
  * Every tile's Exe is the gamectl wrapper (a fixed path, never the
    package's store path) and its LaunchOptions are
    `launch "<Title>"`. appid follows steam-rom-manager's scheme,
    crc32(Exe + AppName) | 0x80000000 stored as signed int32, so with
    a constant Exe an id depends only on the title and survives
    install, eviction and re-install — carrying its play time, art and
    prefix with it.
  * Grid art: grid/<id>p (portrait), <id> (landscape), <id>_hero,
    <id>_logo, <id>_icon, picked up from <title>/art/ in the library.
  * Steam keeps shortcuts.vdf in memory and writes it back on exit, so
    a sync under a running client is skipped instead of lost; the
    gamectl-steam-sync user unit runs it again before the next session
    starts Steam.
  * Entries live in userdata/<SteamID>/config/shortcuts.vdf. The global
    config/shortcuts.vdf is read but not what the library shows.
  * A tile's Exe is a native launcher, so launch runs Proton itself,
    wrapped in steam-run because GE needs Steam's runtime environment.
    The compat-tool machinery is not a fallback here: Steam applies a
    CompatToolMapping to a shortcut whatever its Exe is, so a tool
    picked in a tile's Properties would make Steam run the gamectl
    wrapper under Proton instead of the game — do not set one on these
    tiles. Prefixes go under steamapps/compatdata/<appid> — the same
    root Steam uses for shortcut compat data, shared with it if that
    ever happens — inside the console account's persisted home, so
    evicting a game's files never takes a prefix or its saves with it.
  * Entries this tool owns carry the tag "gamectl"; other shortcuts are
    left alone.
  * Per-title fixes go in the *installed* title's .gamectl marker as
    exe=<path under game/>; the library itself is read-only NFS and
    cannot hold overrides. Tile names follow the library directory.
"""

import argparse
import fcntl
import os
import pwd
import shutil
import subprocess
import sys
import time
import zlib

import vdf

TAG = "gamectl"
# Substrings of executables that are never the game itself.
SKIP = ("unins", "setup", "crash", "redist", "vcredist", "dxwebsetup",
        "dotnet", "physx", "oalinst", "prereq", "install")
# art/<name>.<ext> in a title dir -> grid/<id><suffix>.<ext>
ART = {"portrait": "p", "landscape": "", "hero": "_hero",
       "logo": "_logo", "icon": "_icon"}
ART_EXT = ("png", "jpg")


def log(msg):
    print(msg, flush=True)


def become(user):
    """Re-exec as the console account unless already running as it."""
    if pwd.getpwuid(os.getuid()).pw_name == user:
        return
    script = os.path.realpath(sys.argv[0])
    os.execvp("sudo", ["sudo", "-u", user, "--", script] + sys.argv[1:])


def steam_running():
    uid = os.getuid()
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            if os.stat(f"/proc/{pid}").st_uid != uid:
                continue
            with open(f"/proc/{pid}/comm") as f:
                if f.read().strip() == "steam":
                    return True
        except OSError:
            continue
    return False


def read_marker(title_dir):
    out = {}
    try:
        with open(os.path.join(title_dir, ".gamectl")) as f:
            for line in f:
                key, sep, val = line.rstrip("\n").partition("=")
                if sep:
                    out[key.strip()] = val.strip()
    except FileNotFoundError:
        pass
    return out


def is_elf(path):
    try:
        with open(path, "rb") as f:
            return f.read(4) == b"\x7fELF"
    except OSError:
        return False


def find_exe(root):
    """Return (path, None) or (None, reason). Native beats Windows."""
    native, windows = [], []
    for dirpath, dirnames, filenames in os.walk(root):
        rel = os.path.relpath(dirpath, root)
        depth = 0 if rel == "." else rel.count(os.sep) + 1
        if depth >= 2:
            dirnames[:] = []
        for name in filenames:
            low = name.lower()
            path = os.path.join(dirpath, name)
            if any(s in low for s in SKIP) or os.path.islink(path):
                continue
            if low.endswith(".exe"):
                windows.append((depth, path))
            elif ".so" in low or not os.access(path, os.X_OK):
                continue
            elif low.endswith((".sh", ".x86_64")) or is_elf(path):
                native.append((depth, path))
    for found in (native, windows):
        if not found:
            continue
        top = min(d for d, _ in found)
        at = sorted(p for d, p in found if d == top)
        if len(at) == 1:
            return at[0], None
        names = ", ".join(os.path.relpath(p, root) for p in at)
        return None, f"ambiguous ({names}); set exe=<path under game/> in .gamectl"
    return None, "no executable found; set exe=<path under game/> in .gamectl"


def short_id(exe, name):
    return zlib.crc32((exe + name).encode("utf-8")) | 0x80000000


def signed32(u):
    return u - (1 << 32) if u >= (1 << 31) else u


def unsigned32(s):
    return s + (1 << 32) if s < 0 else s


def merge_tags(old):
    """Keep categories set in Steam; make sure our ownership tag is there."""
    values = list((old or {}).values())
    if TAG not in values:
        values.append(TAG)
    return {str(i): v for i, v in enumerate(values)}


def write_if_changed(path, data, dry):
    old = None
    if os.path.exists(path):
        with open(path, "rb") as f:
            old = f.read()
    if old == data:
        return False
    if dry:
        log(f"  would write {path}")
        return True
    if old is not None:
        shutil.copyfile(path, path + ".gamectl-bak")
    tmp = path + ".gamectl-tmp"
    with open(tmp, "wb") as f:
        f.write(data)
    os.replace(tmp, path)
    log(f"  wrote {path}")
    return True


def desired_titles(args):
    """Every library title, with its stable id — installed or not."""
    try:
        names = sorted(os.listdir(args.library))
    except OSError as e:
        # Heartbeat down or the automount not up yet: keep the grid that
        # is already registered rather than wiping it to nothing.
        log(f"library {args.library} unreadable ({e.strerror}); keeping the current grid")
        return None
    # Quoted the way Steam stores Exe, because that is the string the
    # id is hashed over. The path is fixed (never a store path) so the
    # ids survive every rebuild.
    quoted = f'"{args.wrapper}"'
    startdir = f'"{os.path.dirname(args.wrapper)}"'
    titles = []
    for title in names:
        tdir = os.path.join(args.library, title)
        if not os.path.isfile(os.path.join(tdir, "files", "game-root.dwarfs")):
            continue
        if '"' in title:
            # Steam re-splits LaunchOptions like a shell; a double quote
            # in the name cannot survive the round-trip to argv.
            log(f'skip {title}: name contains ", rename it in Questarr')
            continue
        sid = short_id(quoted, title)
        art = {}
        for kind in ART:
            for ext in ART_EXT:
                src = os.path.join(tdir, "art", f"{kind}.{ext}")
                if os.path.isfile(src):
                    art[kind] = (src, ext)
                    break
        titles.append({
            "title": title, "sid": sid, "quoted": quoted,
            "startdir": startdir, "art": art,
        })
        log(f"title {title}: appid {sid}"
            f"{' (art: ' + ','.join(sorted(art)) + ')' if art else ''}")
    return titles


def sync_user(udir, titles, args):
    cfg = os.path.join(udir, "config")
    grid = os.path.join(cfg, "grid")
    path = os.path.join(cfg, "shortcuts.vdf")
    if os.path.exists(path):
        with open(path, "rb") as f:
            data = vdf.binary_load(f)
    else:
        data = {"shortcuts": {}}
    old = list(data.get("shortcuts", {}).values())

    managed_old = {}
    kept = []
    for e in old:
        tags = e.get("tags") or {}
        if TAG in tags.values():
            managed_old[unsigned32(e.get("appid", 0))] = e
        else:
            kept.append(e)

    new = []
    for t in titles:
        prev = managed_old.get(t["sid"]) or {}
        icon = ""
        if "icon" in t["art"]:
            icon = os.path.join(grid, f"{t['sid']}_icon.{t['art']['icon'][1]}")
        # Start from the existing entry so keys Steam adds itself (sortas,
        # LastPlayTime, ...) survive; the keys below are ours to own.
        entry = dict(prev)
        entry.update({
            "appid": signed32(t["sid"]),
            "AppName": t["title"],
            "Exe": t["quoted"],
            "StartDir": t["startdir"],
            "icon": icon,
            "ShortcutPath": "",
            "LaunchOptions": f'launch "{t["title"]}"',
            "IsHidden": prev.get("IsHidden", 0),
            "AllowDesktopConfig": prev.get("AllowDesktopConfig", 1),
            "AllowOverlay": prev.get("AllowOverlay", 1),
            "OpenVR": 0,
            "Devkit": 0,
            "DevkitGameID": "",
            "DevkitOverrideAppID": 0,
            "LastPlayTime": prev.get("LastPlayTime", 0),
            "FlatpakAppID": "",
            "tags": merge_tags(prev.get("tags")),
        })
        new.append(entry)

    out = {"shortcuts": {str(i): e for i, e in enumerate(kept + new)}}
    os.makedirs(cfg, exist_ok=True)
    write_if_changed(path, vdf.binary_dumps(out), args.dry_run)

    # Grid art: copy (not symlink; Steam may run inside a container),
    # and drop files for ids we no longer own.
    want = {t["sid"] for t in titles}
    stale = set(managed_old) - want
    if not args.dry_run:
        os.makedirs(grid, exist_ok=True)
    for t in titles:
        for kind, suffix in ART.items():
            for ext in ART_EXT:
                dst = os.path.join(grid, f"{t['sid']}{suffix}.{ext}")
                src = t["art"].get(kind)
                if src and src[1] == ext:
                    with open(src[0], "rb") as f:
                        write_if_changed(dst, f.read(), args.dry_run)
                elif os.path.exists(dst) and not args.dry_run:
                    os.remove(dst)
    for sid in stale:
        for suffix in ART.values():
            for ext in ART_EXT:
                dst = os.path.join(grid, f"{sid}{suffix}.{ext}")
                if os.path.exists(dst) and not args.dry_run:
                    os.remove(dst)


def ensure_installed(title, args):
    """A title's local copy appears on first Play, from the read-only
    library. The gamectl wrapper owns the copy/unpack steps."""
    dest = os.path.join(args.games, title)
    if not os.path.isfile(os.path.join(dest, ".gamectl")):
        subprocess.run([args.wrapper, "install", title], check=True)
    return dest


def cmd_launch(title, args):
    if not os.path.isfile(os.path.join(args.library, title,
                                       "files", "game-root.dwarfs")):
        log(f'launch: "{title}" is not in the library')
        return 1
    dest = ensure_installed(title, args)
    gdir = os.path.join(dest, "game")
    marker = read_marker(dest)
    if marker.get("exe"):
        exe = os.path.join(gdir, marker["exe"])
        if not os.path.isfile(exe):
            log(f'launch: exe={marker["exe"]} does not exist')
            return 1
    else:
        exe, why = find_exe(gdir)
        if why:
            log(f"launch: {why}")
            return 1

    # One line per Play: the LRU step reads this ledger (the library
    # mount and the game files are mounted noatime, so file access
    # times cannot answer "which games does he actually play").
    stamp = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    sid = short_id(f'"{args.wrapper}"', title)
    with open(os.path.join(args.games, ".gamectl-launch.log"), "a") as ledger:
        ledger.write(f"{stamp} {title} {exe}\n")
    log(f"launch {title}: appid {sid} exe {exe}")

    if not exe.lower().endswith(".exe"):
        # Launch from the game's own directory: titles resolve data
        # paths relative to the cwd, and whatever we were invoked from
        # (a shell's home over SSH) is no sane default for them.
        os.chdir(gdir)
        os.execv(exe, [exe])

    # Steam must not map a compat tool onto these tiles (it would run
    # the gamectl wrapper under Proton instead of the game), so we run
    # GE-Proton ourselves — waitforexitandrun is the same entry point
    # Steam uses. Note SteamAppID/SteamGameId stay unset here, so
    # GE-Proton's per-game fixes do not engage; no per-title override
    # for that is implemented, the .gamectl marker is where such a key
    # would live if one were needed. The prefix lives under Steam's
    # compatdata root, so it is visible in Properties and survives
    # eviction.
    steam = os.path.expanduser("~/.local/share/Steam")
    pfx = os.path.join(steam, "steamapps", "compatdata", str(sid))
    os.makedirs(pfx, exist_ok=True)
    # bwrap insists on entering the caller's cwd, which it cannot do
    # when invoked from a directory this account cannot traverse
    # (proven over SSH: "bwrap: Can't chdir to ... Permission
    # denied"), so never inherit wherever we were invoked from.
    os.chdir(gdir)
    env = dict(os.environ)
    env["STEAM_COMPAT_DATA_PATH"] = pfx
    env["STEAM_COMPAT_CLIENT_INSTALL_PATH"] = steam
    # Proton's stderr would otherwise land only in Steam's per-session
    # gameprocess log, which is hard to reach from the couch; keep a
    # per-title copy next to the marker. Truncate rather than append,
    # so a game that fails the same way repeatedly cannot grow it
    # without limit. The original descriptor is close-on-exec and
    # closes itself at the exec below; what survives is the dup'd fd 2,
    # which is inheritable — that is what redirects the game's stderr.
    errlog = open(os.path.join(dest, ".gamectl-launch.err"), "w")
    os.dup2(errlog.fileno(), 2)
    log(f"exec {args.runtime} {args.proton} waitforexitandrun {exe} (prefix {pfx})")
    # GE's launcher itself needs a containerized environment (its
    # shebang python, FHS paths for the bundled binaries), so the
    # exec goes through steam-run: NixOS's general-purpose equivalent
    # of the Steam Linux Runtime container in which Steam really runs
    # Proton. A tile launches gamectl from inside Steam's own
    # sandbox, so that case nests one sandbox around another; it is
    # untested until the first Play press proves it (errors land in
    # the .gamectl-launch.err named below).
    os.execve(args.runtime, [args.runtime, args.proton,
                             "waitforexitandrun", exe], env)


def main():
    p = argparse.ArgumentParser(prog="gamectl steam | gamectl launch")
    p.add_argument("--library", required=True, help="read-only Questarr library root")
    p.add_argument("--games", required=True, help="gamectl install root")
    p.add_argument("--user", required=True, help="account that runs Steam")
    p.add_argument("--wrapper", required=True, help="fixed path Steam invokes (hashed into ids)")
    p.add_argument("--proton", required=True, help="GE-Proton launcher script")
    p.add_argument("--runtime", required=True, help="Steam runtime wrapper to run GE inside")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("steam", help="register every library title as a tile")
    s.add_argument("--dry-run", action="store_true")
    launchp = sub.add_parser("launch", help="install if needed, then run a title")
    launchp.add_argument("title")
    args = p.parse_args()

    become(args.user)

    if args.cmd == "launch":
        sys.exit(cmd_launch(args.title, args))

    # Serializes concurrent syncs (the boot-time user unit and manual
    # runs). launch and install deliberately skip the lock: neither
    # ever touches the files a sync writes, and install stays reachable
    # over SSH with Steam stopped, which is exactly why that is safe.
    with open(os.path.join(args.games, ".gamectl-steam.lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if steam_running():
            log("Steam is running; shortcuts sync when the Steam session next starts")
            return
        udata = os.path.join(os.path.expanduser("~/.local/share/Steam"), "userdata")
        users = [os.path.join(udata, u) for u in sorted(os.listdir(udata))
                 if u.isdigit() and u != "0"] if os.path.isdir(udata) else []
        if not users:
            log("no Steam account has logged in yet; nothing to register")
            return
        titles = desired_titles(args)
        if titles is None:
            return
        for u in users:
            log(f"account {os.path.basename(u)}:")
            sync_user(u, titles, args)


if __name__ == "__main__":
    main()
