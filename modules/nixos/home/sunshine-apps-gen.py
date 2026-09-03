#!/usr/bin/env python3
"""Regenerate the Sunshine application catalog from installed games."""

import getpass
import json
import re
import subprocess
import urllib.request
from pathlib import Path

MAGICK = "magick"

HOME = Path.home()
STEAMAPPS = HOME / ".local/share/Steam/steamapps"
LIBCACHE = HOME / ".local/share/Steam/appcache/librarycache"
HEROIC = HOME / ".config/heroic"
COVERS = HOME / ".config/sunshine/covers"
APPS_JSON = HOME / ".config/sunshine/apps.json"

SKIP = re.compile(r"Proton|Steam Linux Runtime|Steamworks|EasyAntiCheat")

RES_PREP = {"do": "sunshine-res set", "undo": "sunshine-res restore"}
KILL_PREP = {"do": "", "undo": "pkill -f gamescope; pkill -f steam; true"}
KILL_PREP_HEROIC = {"do": "", "undo": "pkill -f gamescope; pkill -f heroic; true"}
KILL_PREP_WINE = {"do": "", "undo": "pkill -f gamescope; pkill -f umu; true"}


def png_from_jpg(src, appid):
    COVERS.mkdir(parents=True, exist_ok=True)
    dst = COVERS / (appid + ".png")
    if not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime:
        subprocess.run([MAGICK, str(src), str(dst)], check=True)
    return str(dst)


def png_from_url(url, key):
    if not url:
        return None
    COVERS.mkdir(parents=True, exist_ok=True)
    dst = COVERS / (key + ".png")
    if dst.exists():
        return str(dst)
    try:
        raw = COVERS / (key + ".raw")
        urllib.request.urlretrieve(url, raw)
        subprocess.run([MAGICK, str(raw), str(dst)], check=True)
        raw.unlink(missing_ok=True)
        return str(dst)
    except Exception:
        return None


def steam_games():
    out = []
    for acf in sorted(STEAMAPPS.glob("appmanifest_*.acf")):
        text = acf.read_text(errors="replace")
        appid = re.search(r'"appid"\s+"(\d+)"', text)
        name = re.search(r'"name"\s+"([^"]+)"', text)
        if not appid or not name or SKIP.search(name.group(1)):
            continue
        appid, name = appid.group(1), name.group(1)
        entry = {
            "name": name,
            "cmd": "steam-run-game " + appid,
            "prep-cmd": [RES_PREP, KILL_PREP],
        }
        art = LIBCACHE / appid / "library_600x900.jpg"
        if art.exists():
            entry["image-path"] = png_from_jpg(art, appid)
        out.append(entry)
    return out


def heroic_games():
    out = []
    installed = HEROIC / "legendaryConfig/legendary/installed.json"
    lib_cache = HEROIC / "store_cache/legendary_library.json"
    art_by_app = {}
    if lib_cache.exists():
        lib = json.loads(lib_cache.read_text())
        for game in lib.get("library", []):
            art_by_app[game.get("app_name")] = game.get("art_cover") or game.get("art_square")
    if installed.exists():
        for app_name, meta in json.loads(installed.read_text()).items():
            if meta.get("is_dlc"):
                continue
            title = meta.get("title") or app_name
            entry = {
                "name": title,
                "cmd": "heroic-run-game legendary " + app_name,
                "prep-cmd": [RES_PREP, KILL_PREP_HEROIC],
            }
            art = png_from_url(art_by_app.get(app_name), "epic-" + app_name)
            if art:
                entry["image-path"] = art
            out.append(entry)
    gog_installed = HEROIC / "gog_store/installed.json"
    gog_lib = HEROIC / "store_cache/gog_library.json"
    title_by_app, art_by_gog = {}, {}
    if gog_lib.exists():
        lib = json.loads(gog_lib.read_text())
        for game in lib.get("games", []):
            title_by_app[game.get("app_name")] = game.get("title")
            art_by_gog[game.get("app_name")] = game.get("art_cover") or game.get("art_square")
    if gog_installed.exists():
        for game in json.loads(gog_installed.read_text()).get("installed", []):
            app_name = game.get("appName")
            title = title_by_app.get(app_name) or app_name
            entry = {
                "name": title,
                "cmd": "heroic-run-game gog " + app_name,
                "prep-cmd": [RES_PREP, KILL_PREP_HEROIC],
            }
            art = png_from_url(art_by_gog.get(app_name), "gog-" + app_name)
            if art:
                entry["image-path"] = art
            out.append(entry)
    return out


def extra_apps():
    path = APPS_JSON.parent / "extra-apps.json"
    if not path.exists():
        return []
    out = []
    for entry in json.loads(path.read_text()).get("apps", []):
        entry.setdefault("prep-cmd", [RES_PREP, KILL_PREP_WINE])
        out.append(entry)
    return out


games = steam_games() + heroic_games() + extra_apps()

user = getpass.getuser()
apps = {
    "env": {
        "PATH": "/etc/profiles/per-user/" + user + "/bin:/run/current-system/sw/bin",
        "WAYLAND_DISPLAY": "wayland-1",
        "XDG_RUNTIME_DIR": "/run/user/1000",
        "DISPLAY": ":0",
    },
    "apps": [
        {"name": "Desktop", "prep-cmd": [RES_PREP], "image-path": "desktop.png"},
        {
            "name": "Steam Big Picture",
            "cmd": "steam-bigpicture",
            "prep-cmd": [RES_PREP, KILL_PREP],
            "image-path": "steam.png",
        },
    ]
    + sorted(games, key=lambda game: game["name"].lower()),
}

APPS_JSON.write_text(json.dumps(apps, indent=2) + "\n")
print("wrote " + str(APPS_JSON) + " with " + str(len(games)) + " entries:")
for game in sorted(games, key=lambda item: item["name"].lower()):
    print("  " + game["name"])
