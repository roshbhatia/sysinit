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
      pkgs.nushell
    ];
    meta = {
      description = "Agent notifications using the macOS UserNotifications framework";
      homepage = "https://github.com/julienXX/terminal-notifier";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
    };
  }
  ''
    app="$out/Applications/CLI Agents.app"
    mkdir -p "$app"
    cp -R ${pkgs.terminal-notifier}/Applications/terminal-notifier.app/. "$app/"
    chmod -R u+w "$app"
    mkdir icon-images
    for size in 16 32 48 128 256 512 1024; do
      rsvg-convert --width "$size" --height "$size" --background-color '#FFFFFF' \
        ${icon} --output "icon-images/$size.png"
    done
    png2icns "$app/Contents/Resources/CLIAgents.icns" icon-images/*.png
    nu --no-config-file --plugins ${lib.getExe pkgs.nushellPlugins.formats} \
      ${./notifier-plist.nu} "$app/Contents/Info.plist"
    /usr/bin/codesign --force --sign - --timestamp=none "$app"
    /usr/bin/codesign --verify --deep --strict "$app"
  ''
