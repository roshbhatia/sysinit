import QtQuick
import qs.Theme
import qs.Services

Row {
    spacing: 6
    visible: NiriService.focusedWindowAppId !== ""
    height: Theme.barHeight

    property string appId: NiriService.focusedWindowAppId

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
        "pavucontrol": "\udb81\udd53",
        "eog": "\udb80\ude0b",
        "mpv": "\udb80\udcf8",
        "vlc": "\udb80\udcf8",
        "steam": "\uf1b6",
        "1password": "\udb80\udcca",
        "evince": "\uf1c1",
        "zathura": "\uf1c1"
    })

    property string icon: iconMap[appId] || "\uf108"

    Text {
        text: parent.icon
        color: Theme.textDim
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: {
            var name = parent.appId
            if (name.indexOf(".") !== -1) {
                var parts = name.split(".")
                name = parts[parts.length - 1]
            }
            if (name.length > 0)
                name = name.charAt(0).toUpperCase() + name.slice(1)
            if (name.length > 20)
                name = name.substring(0, 18) + "…"
            return name
        }
        color: Theme.textDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        anchors.verticalCenter: parent.verticalCenter
    }
}
