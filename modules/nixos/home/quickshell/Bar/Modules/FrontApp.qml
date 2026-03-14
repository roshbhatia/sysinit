import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Common
import qs.Services

RowLayout {
    spacing: 6
    visible: NiriService.focusedWindowAppId !== ""

    property string appId: NiriService.focusedWindowAppId
    property string appTitle: NiriService.focusedWindowTitle

    // Nerd font icon mapping for common apps
    property var iconMap: ({
        "firefox": "\udb80\ude09",
        "firefox-esr": "\udb80\ude09",
        "chromium-browser": "\udb80\udead",
        "google-chrome": "\udb80\udead",
        "brave-browser": "\udb80\udead",
        "org.wezfurlong.wezterm": "\udb80\uddc5",
        "wezterm": "\udb80\uddc5",
        "Alacritty": "\ue795",
        "kitty": "\uf490",
        "foot": "\uf489",
        "discord": "\udb80\udc6f",
        "vesktop": "\udb80\udc6f",
        "Slack": "\udb81\udcb1",
        "slack": "\udb81\udcb1",
        "spotify": "\udb80\udd07",
        "thunderbird": "\udb80\udc6e",
        "code": "\udb82\ude1e",
        "Code": "\udb82\ude1e",
        "code-oss": "\udb82\ude1e",
        "codium": "\udb82\ude1e",
        "neovide": "\ue62b",
        "org.gnome.Nautilus": "\udb80\udcc1",
        "nemo": "\udb80\udcc1",
        "thunar": "\udb80\udcc1",
        "dolphin": "\udb80\udcc1",
        "org.telegram.desktop": "\uf2c6",
        "signal": "\uf086",
        "ferdium": "\uf075",
        "obsidian": "\uf249",
        "notion": "\uf249",
        "org.gnome.Settings": "\uf013",
        "gnome-control-center": "\uf013",
        "pavucontrol": "\udb81\udd53",
        "nm-applet": "\udb80\udf1e",
        "eog": "\udb80\ude0b",
        "mpv": "\udb80\udcf8",
        "vlc": "\udb80\udcf8",
        "gimp": "\uf1fc",
        "inkscape": "\uf1fc",
        "blender": "\uf1fc",
        "steam": "\uf1b6",
        "lutris": "\uf11b",
        "1password": "\udb80\udcca",
        "org.keepassxc.KeePassXC": "\udb80\udcca",
        "libreoffice-writer": "\udb80\udde9",
        "libreoffice-calc": "\udb80\udde9",
        "libreoffice-impress": "\udb80\udde9",
        "evince": "\uf1c1",
        "zathura": "\uf1c1",
        "transmission-gtk": "\udb80\udc96",
        "virt-manager": "\uf108"
    })

    property string icon: iconMap[appId] || "\uf108"

    Text {
        text: parent.icon
        color: Theme.text
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        verticalAlignment: Text.AlignVCenter
    }

    DefaultText {
        text: {
            // Show a clean app name
            var name = parent.appId
            if (name.indexOf(".") !== -1) {
                var parts = name.split(".")
                name = parts[parts.length - 1]
            }
            // Capitalize first letter
            if (name.length > 0) {
                name = name.charAt(0).toUpperCase() + name.slice(1)
            }
            // Truncate
            if (name.length > 24) {
                name = name.substring(0, 22) + "…"
            }
            return name
        }
        verticalAlignment: Text.AlignVCenter
    }
}
