import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Theme

Row {
    id: vol
    spacing: 5
    height: Theme.barHeight

    property var sink: Pipewire.defaultAudioSink
    property var audio: sink ? sink.audio : null
    property real volume: audio ? audio.volume : 0
    property bool muted: audio ? audio.muted : false
    property int pct: Math.round(volume * 100)

    property string icon: {
        if (muted || pct === 0) return "\udb82\udd08"
        if (pct < 30) return "\udb80\udd7f"
        if (pct < 70) return "\udb80\udd80"
        return "\udb80\udd7e"
    }

    Text {
        text: vol.icon
        color: vol.muted ? Theme.textMuted : Theme.text
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: vol.pct + "%"
        color: vol.muted ? Theme.textMuted : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        anchors.verticalCenter: parent.verticalCenter
    }
}
