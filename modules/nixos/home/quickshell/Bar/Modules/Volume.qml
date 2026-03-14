import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Theme
import qs.Common

RowLayout {
    id: volumeWidget
    spacing: 6

    property var sink: Pipewire.defaultAudioSink
    property var audio: sink ? sink.audio : null
    property real volume: audio ? audio.volume : 0
    property bool muted: audio ? audio.muted : false

    property int volumePercent: Math.round(volume * 100)

    property string icon: {
        if (muted || volumePercent === 0) return "\udb82\udd08"
        if (volumePercent < 30) return "\udb80\udd7f"
        if (volumePercent < 70) return "\udb80\udd80"
        return "\udb80\udd7e"
    }

    Text {
        text: volumeWidget.icon
        color: volumeWidget.muted ? Theme.textMuted : Theme.text
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        verticalAlignment: Text.AlignVCenter
    }

    DefaultText {
        text: volumeWidget.volumePercent + "%"
        color: volumeWidget.muted ? Theme.textMuted : Theme.text
        verticalAlignment: Text.AlignVCenter
    }

    // Slider (visible on hover)
    Rectangle {
        id: sliderBg
        width: 80
        height: 6
        radius: 3
        color: Theme.surface
        visible: hoverArea.containsMouse

        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            width: parent.width * Math.min(1, volumeWidget.volume)
            height: parent.height
            radius: 3
            color: volumeWidget.muted ? Theme.textMuted : Theme.blue
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => {
                if (volumeWidget.audio) {
                    volumeWidget.audio.volume = mouse.x / parent.width
                }
            }
            onPositionChanged: mouse => {
                if (pressed && volumeWidget.audio) {
                    volumeWidget.audio.volume = Math.max(0, Math.min(1, mouse.x / parent.width))
                }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true

        onWheel: wheel => {
            if (volumeWidget.audio) {
                var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                volumeWidget.audio.volume = Math.max(0, Math.min(1, volumeWidget.volume + delta))
            }
        }
    }
}
