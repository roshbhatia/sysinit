import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// Main taskbar/panel with retroism styling
ShellRoot {
  id: root

  // Top panel taskbar
  Panel {
    id: mainPanel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 32

    background: Rectangle {
      color: "#0d1117" // retroism dark bg0
      border.color: "#39ff14" // retroism green fg0
      border.width: 2
    }

    RowLayout {
      anchors.fill: parent
      anchors.margins: 4
      spacing: 8

      // Workspace indicator
      Text {
        text: "WS: 1"
        color: "#39ff14" // phosphor green
        font.family: "monospace"
        font.pixelSize: 12
        font.bold: true
      }

      Rectangle {
        color: "#39ff14"
        Layout.preferredWidth: 1
        Layout.fillHeight: true
      }

      // System tray placeholder
      Text {
        text: "System"
        color: "#00e676" // brighter green
        font.family: "monospace"
        font.pixelSize: 10
        Layout.rightMargin: 8
      }

      Item {
        Layout.fillWidth: true
      }

      // Clock
      Text {
        text: {
          var date = new Date();
          return Qt.formatTime(date, "hh:mm:ss");
        }
        color: "#39ff14"
        font.family: "monospace"
        font.pixelSize: 10

        Timer {
          interval: 1000
          running: true
          repeat: true
          onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm:ss")
        }
      }
    }
  }

  // Example floating launcher button
  Rectangle {
    id: launcherBtn
    x: 16
    y: 64
    width: 48
    height: 48

    color: "#1f1200" // amber variant bg0
    border.color: "#ffb90f" // amber fg0
    border.width: 2

    Text {
      anchors.centerIn: parent
      text: "⚙"
      color: "#ffb90f"
      font.pixelSize: 24
    }

    MouseArea {
      anchors.fill: parent
      onClicked: console.log("Launcher clicked")
    }
  }
}
