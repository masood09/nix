"""Register every gamectl-installed title as a Steam non-Steam shortcut.

Run as `gamectl steam [--dry-run]`; gamectl passes --games, --tool and
--user. Re-executes itself as --user (the console account) when started
by anyone else, since Steam's files and the games' Proton prefixes
belong to that account.

Steam keeps shortcuts.vdf and config.vdf in memory and writes them back
on exit, so edits made under a running client are lost. While Steam
runs this exits without writing; the gamectl-steam-sync user unit runs
it again before the next session starts Steam.

Format and ids follow steam-rom-manager:
  * shortcuts.vdf is binary VDF: {"shortcuts": {"0": {...}, "1": {...}}}
  * appid = crc32(Exe + AppName) | 0x80000000, stored as signed int32,
    so an entry keeps its id (and its play time, art and Proton prefix)
    across re-runs
  * grid art: grid/<id>p (portrait), <id> (landscape), <id>_hero,
    <id>_logo, <id>_icon
  * Proton: config/config.vdf
    InstallConfigStore/Software/Valve/Steam/CompatToolMapping/<id>
Entries this tool owns carry the tag "gamectl"; others are left alone.

Per-title overrides go in the title's .gamectl marker as key=value
lines: exe=<path under game/>, name=<tile name>, args=<launch options>.
Artwork is picked up from <title>/art/{portrait,landscape,hero,logo,icon}
.{png,jpg}.
"""

import argparse
import fcntl
import os
import pwd
import shutil
import sys
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
    with open(os.path.join(title_dir, ".gamectl")) as f:
        for line in f:
            key, sep, val = line.rstrip("\n").partition("=")
            if sep:
                out[key.strip()] = val.strip()
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


def ci_child(d, key):
    """Case-insensitive dict descent, creating the level if missing."""
    for k in d:
        if k.lower() == key.lower():
            return d[k]
    d[key] = {}
    return d[key]


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


def desired_titles(games):
    titles = []
    for title in sorted(os.listdir(games)):
        tdir = os.path.join(games, title)
        if not os.path.isfile(os.path.join(tdir, ".gamectl")):
            continue
        marker = read_marker(tdir)
        gdir = os.path.join(tdir, "game")
        if marker.get("exe"):
            exe = os.path.join(gdir, marker["exe"])
            why = None if os.path.isfile(exe) else f"exe={marker['exe']} does not exist"
        else:
            exe, why = find_exe(gdir)
        if why:
            log(f"skip {title}: {why}")
            continue
        name = marker.get("name", title)
        quoted = f'"{exe}"'
        sid = short_id(quoted, name)
        art = {}
        for kind in ART:
            for ext in ART_EXT:
                src = os.path.join(tdir, "art", f"{kind}.{ext}")
                if os.path.isfile(src):
                    art[kind] = (src, ext)
                    break
        titles.append({
            "title": title, "name": name, "exe": exe, "quoted": quoted,
            "sid": sid, "windows": exe.lower().endswith(".exe"),
            "args": marker.get("args", ""), "art": art,
        })
        kind = "windows/proton" if titles[-1]["windows"] else "native"
        log(f"title {name}: {os.path.relpath(exe, gdir)} ({kind}, appid {sid})")
    return titles


def sync_user(udir, titles, dry):
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
    wanted_exes = {t["quoted"] for t in titles}
    for e in old:
        tags = e.get("tags") or {}
        exe = e.get("Exe", e.get("exe", ""))
        if TAG in tags.values() or exe in wanted_exes:
            # Ours, or a hand-added tile for the same binary: adopt it so
            # it does not show up twice.
            managed_old[unsigned32(e.get("appid", 0))] = e
        else:
            kept.append(e)

    by_exe = {e.get("Exe", e.get("exe", "")): e for e in managed_old.values()}
    new = []
    for t in titles:
        prev = managed_old.get(t["sid"]) or by_exe.get(t["quoted"]) or {}
        icon = ""
        if "icon" in t["art"]:
            icon = os.path.join(grid, f"{t['sid']}_icon.{t['art']['icon'][1]}")
        # Start from the existing entry so keys Steam adds itself (sortas,
        # LastPlayTime, ...) survive; the keys below are ours to own.
        entry = dict(prev)
        entry.update({
            "appid": signed32(t["sid"]),
            "AppName": t["name"],
            "Exe": t["quoted"],
            "StartDir": f'"{os.path.dirname(t["exe"])}"',
            "icon": icon,
            "ShortcutPath": "",
            "LaunchOptions": t["args"],
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
    write_if_changed(path, vdf.binary_dumps(out), dry)

    # Grid art: copy (not symlink; Steam runs inside a bwrap FHS env),
    # and drop files for ids we no longer own.
    want = {t["sid"] for t in titles}
    stale = set(managed_old) - want
    if not dry:
        os.makedirs(grid, exist_ok=True)
    for t in titles:
        for kind, suffix in ART.items():
            for ext in ART_EXT:
                dst = os.path.join(grid, f"{t['sid']}{suffix}.{ext}")
                src = t["art"].get(kind)
                if src and src[1] == ext:
                    with open(src[0], "rb") as f:
                        write_if_changed(dst, f.read(), dry)
                elif os.path.exists(dst) and not dry:
                    os.remove(dst)
    for sid in stale:
        for suffix in ART.values():
            for ext in ART_EXT:
                dst = os.path.join(grid, f"{sid}{suffix}.{ext}")
                if os.path.exists(dst) and not dry:
                    os.remove(dst)
    return set(managed_old)


def sync_compat(steam, titles, owned_before, tool, dry):
    path = os.path.join(steam, "config", "config.vdf")
    if not os.path.exists(path):
        log("skip compat: no config.vdf (Steam never started?)")
        return
    with open(path, encoding="utf-8") as f:
        cfg = vdf.load(f)
    mapping = cfg
    for key in ("InstallConfigStore", "Software", "Valve", "Steam",
                "CompatToolMapping"):
        mapping = ci_child(mapping, key)
    before = {k: dict(v) for k, v in mapping.items()}
    want = {str(t["sid"]) for t in titles}
    for sid in owned_before:
        if str(sid) not in want:
            mapping.pop(str(sid), None)
    for t in titles:
        if t["windows"] and str(t["sid"]) not in mapping:
            # Only fill a missing mapping: a tool picked later in the
            # Properties dialog survives every re-sync.
            mapping[str(t["sid"])] = {"name": tool, "config": "",
                                      "priority": "250"}
    # vdf re-serialises with different whitespace than Steam, so only
    # rewrite when the mapping really changed (Steam reformats on exit).
    if mapping == before:
        return
    write_if_changed(path, vdf.dumps(cfg, pretty=True).encode("utf-8"), dry)


def main():
    p = argparse.ArgumentParser(prog="gamectl steam")
    p.add_argument("--games", required=True, help="gamectl install root")
    p.add_argument("--tool", required=True, help="Steam compat tool for .exe titles")
    p.add_argument("--user", required=True, help="account that runs Steam")
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    become(args.user)
    steam = os.path.expanduser("~/.local/share/Steam")

    # Shared with the user unit, so a manual sync in flight finishes
    # before a starting session reads Steam's files.
    with open(os.path.join(args.games, ".gamectl-steam.lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if steam_running():
            log("Steam is running; shortcuts sync when the Steam session next starts")
            return
        udata = os.path.join(steam, "userdata")
        users = [os.path.join(udata, u) for u in sorted(os.listdir(udata))
                 if u.isdigit() and u != "0"] if os.path.isdir(udata) else []
        if not users:
            log("no Steam account has logged in yet; nothing to register")
            return
        titles = desired_titles(args.games)
        owned = set()
        for u in users:
            log(f"account {os.path.basename(u)}:")
            owned |= sync_user(u, titles, args.dry_run)
        sync_compat(steam, titles, owned, args.tool, args.dry_run)


if __name__ == "__main__":
    main()
