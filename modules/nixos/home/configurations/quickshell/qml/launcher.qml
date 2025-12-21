import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// Application launcher with grid view of available apps
ShellRoot {
  id: root

  // Hidden by default, shown on hotkey
  visible: false

  // Main launcher window
  Rectangle {
    id: launcherWindow
    anchors.centerIn: parent
    width: 600
    height: 500

    color: "#0d1117" // retroism dark bg0
    border.color: "#39ff14" // phosphor green
    border.width: 3

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 8
      spacing: 8

      // Search input
      Rectangle {
        color: "#161b22" // bg1
        border.color: "#00e5ff" // cyan accent
        border.width: 2
        Layout.fillWidth: true
        height: 40

        TextInput {
          id: searchInput
          anchors.fill: parent
          anchors.margins: 8
          color: "#39ff14"
          font.family: "monospace"
          font.pixelSize: 14
          placeholder: "Search applications..."
          placeholderTextColor: "#666666"
        }
      }

      // Application grid
      GridView {
        id: appGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        cellWidth: 100
        cellHeight: 100

        model: 12 // Placeholder for actual apps

        delegate: Rectangle {
          width: 90
          height: 90
          color: "#21262d" // bg2
          border.color: "#39ff14"
          border.width: 1
          radius: 4

          ColumnLayout {
            anchors.centerIn: parent
            anchors.margins: 4
            spacing: 4

            Text {
              text: "App " + (index + 1)
              color: "#39ff14"
              font.family: "monospace"
              font.pixelSize: 10
              Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
              width: 32
              height: 32
              color: "#30363d" // bg3
              radius: 2
              Layout.alignment: Qt.AlignHCenter
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: parent.border.color = "#00e5ff"
            onExited: parent.border.color = "#39ff14"
            onClicked: console.log("Launch app " + (index + 1))
          }
        }
      }

      // Footer with category tabs
      Rectangle {
        color: "#30363d" // bg3
        border.color: "#39ff14"
        border.width: 1
        Layout.fillWidth: true
        height: 30

        RowLayout {
          anchors.fill: parent
          anchors.margins: 4
          spacing: 8

          Text {
            text: "All"
            color: "#00e5ff"
            font.family: "monospace"
            font.pixelSize: 10
          }

          Text {
            text: "Tools"
            color: "#39ff14"
            font.family: "monospace"
            font.pixelSize: 10
          }

          Text {
            text: "System"
            color: "#39ff14"
            font.family: "monospace"
            font.pixelSize: 10
          }

          Item {
            Layout.fillWidth: true
          }
        }
      }
    }

    // Handle Escape to close
    Keys.onPressed: {
      if (event.key === Qt.Key_Escape) {
        launcherWindow.visible = false;
        event.accepted = true;
      }
    }
  }

  // Show launcher on Super+p hotkey
  Shortcut {
    sequences: ["Super+p"]
    onActivated: launcherWindow.visible = !launcherWindow.visible
  }
}
