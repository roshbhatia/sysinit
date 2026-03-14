import QtQuick
import qs.Theme
import qs.Services

Row {
    property var screen
    spacing: 6
    height: Theme.barHeight

    Repeater {
        model: {
            var ws = NiriService.allWorkspaces
            if (!screen) return ws
            return ws.filter(function(w) { return w.output === screen.name })
        }

        Rectangle {
            required property var modelData
            property int wsIndex: modelData.idx - 1
            property bool isActive: modelData.is_focused || false
            property color dotColor: Theme.dotColors[wsIndex % Theme.dotColors.length]

            width: 8
            height: 8
            radius: 4
            anchors.verticalCenter: parent.verticalCenter

            color: isActive ? dotColor : "transparent"
            border.width: isActive ? 0 : 1.2
            border.color: dotColor

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NiriService.switchToWorkspace(parent.modelData.idx)
            }
        }
    }
}
