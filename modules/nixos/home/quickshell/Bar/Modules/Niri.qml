import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Common
import qs.Services

RowLayout {
    id: workspaceDots

    property var screen

    spacing: 8

    Repeater {
        model: {
            var ws = NiriService.allWorkspaces
            if (!screen) return ws
            return ws.filter(function(w) {
                return w.output === screen.name
            })
        }

        Rectangle {
            required property var modelData
            property int wsIndex: modelData.idx - 1
            property bool isActive: modelData.is_focused || false
            property color dotColor: Theme.dotColors[wsIndex % Theme.dotColors.length]

            width: 14
            height: 14
            radius: width / 2

            color: isActive ? dotColor : "transparent"
            border.width: isActive ? 0 : 1.5
            border.color: dotColor

            MouseArea {
                anchors.fill: parent
                onClicked: NiriService.switchToWorkspace(parent.modelData.idx)
            }
        }
    }

    // Show focused workspace index number
    DefaultText {
        text: NiriService.focusedWorkspaceIndex >= 0 ? NiriService.focusedWorkspaceIndex.toString() : ""
        color: Theme.textMuted
        font.pixelSize: Theme.fontSize - 2
        visible: text !== ""
        verticalAlignment: Text.AlignVCenter
    }
}
