{
  lib,
  pkgs,
  icon,
}:
pkgs.runCommand "sysinit-agents-notifier-${pkgs.terminal-notifier.version}"
  {
    nativeBuildInputs = [
      pkgs.librsvg
      pkgs.libicns
      pkgs.python3
    ];
    meta = {
      description = "Agent notifications using the macOS UserNotifications framework";
      homepage = "https://github.com/julienXX/terminal-notifier";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
    };
  }
  ''
    app="$out/Applications/Sysinit Agents.app"
    mkdir -p "$app"
    cp -R ${pkgs.terminal-notifier}/Applications/terminal-notifier.app/. "$app/"
    chmod -R u+w "$app"
    mkdir icon-images
    for size in 16 32 48 128 256 512 1024; do
      rsvg-convert --width "$size" --height "$size" --background-color '#FFFFFF' \
        ${icon} --output "icon-images/$size.png"
    done
    png2icns "$app/Contents/Resources/SysinitAgents.icns" icon-images/*.png
    python3 - "$app/Contents/Info.plist" <<'PY'
    import plistlib
    import sys
    from pathlib import Path
    path = Path(sys.argv[1])
    with path.open("rb") as source:
        info = plistlib.load(source)
    info.update(
        CFBundleIdentifier="org.roshbhatia.sysinit.agents",
        CFBundleName="Sysinit Agents",
        CFBundleDisplayName="Sysinit Agents",
        CFBundleIconFile="SysinitAgents",
    )
    with path.open("wb") as target:
        plistlib.dump(info, target)
    PY
    /usr/bin/codesign --force --sign - --timestamp=none "$app"
    /usr/bin/codesign --verify --deep --strict "$app"
  ''
