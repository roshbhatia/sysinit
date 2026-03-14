import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.Theme
import qs.Common

RowLayout {
    id: musicWidget
    spacing: 6

    property var player: {
        var players = Mpris.players
        if (players && players.values && players.values.length > 0) {
            return players.values[0]
        }
        return null
    }

    property bool hasTrack: player !== null && player.trackTitle !== ""

    visible: hasTrack

    Text {
        text: {
            if (!musicWidget.player) return ""
            return musicWidget.player.playbackState === MprisPlaybackState.Playing
                ? "\udb81\udc0a" : "\udb80\udfa4"
        }
        color: Theme.green
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        verticalAlignment: Text.AlignVCenter

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (musicWidget.player) {
                    musicWidget.player.togglePlaying()
                }
            }
        }
    }

    DefaultText {
        text: {
            if (!musicWidget.player) return ""
            var title = musicWidget.player.trackTitle || ""
            var artists = musicWidget.player.trackArtists || []
            var artist = artists.length > 0 ? artists[0] : ""
            var display = title
            if (artist !== "") display += " - " + artist
            if (display.length > 36) display = display.substring(0, 34) + "…"
            return display
        }
        color: Theme.textDim
        verticalAlignment: Text.AlignVCenter
    }
}
