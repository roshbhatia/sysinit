import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Theme

Row {
    id: musicWidget
    spacing: 6
    height: Theme.barHeight

    property var player: {
        var players = Mpris.players
        if (players && players.values && players.values.length > 0)
            return players.values[0]
        return null
    }

    visible: player !== null && player.trackTitle !== ""

    Text {
        text: {
            if (!musicWidget.player) return ""
            return musicWidget.player.playbackState === MprisPlaybackState.Playing
                ? "\udb81\udc0a" : "\udb80\udfa4"
        }
        color: Theme.green
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            onClicked: if (musicWidget.player) musicWidget.player.togglePlaying()
        }
    }

    Text {
        text: {
            if (!musicWidget.player) return ""
            var t = musicWidget.player.trackTitle || ""
            var a = (musicWidget.player.trackArtists || [])
            var artist = a.length > 0 ? a[0] : ""
            var s = t
            if (artist) s += " — " + artist
            if (s.length > 30) s = s.substring(0, 28) + "…"
            return s
        }
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        anchors.verticalCenter: parent.verticalCenter
    }
}
