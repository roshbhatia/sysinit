import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// Settings menu for theme, wallpaper, and system info
ShellRoot {
  id: root

  visible: false

  // Settings window
  Rectangle {
    id: settingsWindow
    anchors.centerIn: parent
    width: 500
    height: 600

    color: "#0d1117" // retroism dark bg0
    border.color: "#39ff14" // phosphor green
    border.width: 3

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 12

      // Title
      Text {
        text: "SYSTEM SETTINGS"
        color: "#39ff14"
        font.family: "monospace"
        font.pixelSize: 16
        font.bold: true
        Layout.alignment: Qt.AlignHCenter
      }

      Rectangle {
        color: "#39ff14"
        height: 2
        Layout.fillWidth: true
      }

      // Theme section
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: "THEME"
          color: "#00e5ff"
          font.family: "monospace"
          font.pixelSize: 12
          font.bold: true
        }

        Rectangle {
          color: "#21262d" // bg2
          border.color: "#39ff14"
          border.width: 1
          Layout.fillWidth: true
          height: 40

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text {
              text: "Variant:"
              color: "#39ff14"
              font.family: "monospace"
              font.pixelSize: 10
            }

            ComboBox {
              model: ["Dark", "Amber", "Green"]
              currentIndex: 0
              Layout.fillWidth: true

              contentItem: Text {
                color: "#39ff14"
                text: parent.currentText
                font.family: "monospace"
                font.pixelSize: 10
              }

              background: Rectangle {
                color: "#30363d"
                border.color: "#39ff14"
              }

              onCurrentIndexChanged: {
                console.log("Theme changed to: " + model[currentIndex])
              }
            }
          }
        }
      }

      // Wallpaper section
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: "WALLPAPER"
          color: "#00e5ff"
          font.family: "monospace"
          font.pixelSize: 12
          font.bold: true
        }

        Rectangle {
          color: "#21262d"
          border.color: "#39ff14"
          border.width: 1
          Layout.fillWidth: true
          height: 40

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text {
              text: "Current:"
              color: "#39ff14"
              font.family: "monospace"
              font.pixelSize: 10
            }

            Text {
              text: "retroism-default.png"
              color: "#00e676"
              font.family: "monospace"
              font.pixelSize: 10
              Layout.fillWidth: true
            }
          }
        }

        Button {
          text: "Change Wallpaper"
          Layout.fillWidth: true
          height: 36

          background: Rectangle {
            color: "#21262d"
            border.color: "#39ff14"
            border.width: 2
          }

          contentItem: Text {
            text: parent.text
            color: "#39ff14"
            font.family: "monospace"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          MouseArea {
            anchors.fill: parent
            onClicked: console.log("Open wallpaper selector")
          }
        }
      }

      // System Info section
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: "SYSTEM INFO"
          color: "#00e5ff"
          font.family: "monospace"
          font.pixelSize: 12
          font.bold: true
        }

        Rectangle {
          color: "#21262d"
          border.color: "#39ff14"
          border.width: 1
          Layout.fillWidth: true
          Layout.minimumHeight: 120

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text {
              text: "OS: NixOS"
              color: "#39ff14"
              font.family: "monospace"
              font.pixelSize: 10
            }

            Text {
              text: "WM: MangoWC"
              color: "#39ff14"
              font.family: "monospace"
              font.pixelSize: 10
            }

            Text {
              text: "Terminal: Wezterm"
              color: "#39ff14"
              font.family: "monospace"
              font.pixelSize: 10
            }

            Text {
              text: "Shell: zsh"
              color: "#39ff14"
              font.family: "monospace"
              font.pixelSize: 10
            }

            Rectangle {
              color: "#39ff14"
              height: 1
              Layout.fillWidth: true
            }

            Text {
              text: "Appearance: Retroism"
              color: "#00e5ff"
              font.family: "monospace"
              font.pixelSize: 10
              font.bold: true
            }
          }
        }
      }

      Item {
        Layout.fillHeight: true
      }

      // Footer buttons
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Button {
          text: "Apply"
          Layout.fillWidth: true
          height: 36

          background: Rectangle {
            color: "#21262d"
            border.color: "#00ff00"
            border.width: 2
          }

          contentItem: Text {
            text: parent.text
            color: "#00ff00"
            font.family: "monospace"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          MouseArea {
            anchors.fill: parent
            onClicked: console.log("Apply settings")
          }
        }

        Button {
          text: "Close"
          Layout.fillWidth: true
          height: 36

          background: Rectangle {
            color: "#21262d"
            border.color: "#39ff14"
            border.width: 2
          }

          contentItem: Text {
            text: parent.text
            color: "#39ff14"
            font.family: "monospace"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          MouseArea {
            anchors.fill: parent
            onClicked: settingsWindow.visible = false
          }
        }
      }
    }

    // Handle Escape to close
    Keys.onPressed: {
      if (event.key === Qt.Key_Escape) {
        settingsWindow.visible = false;
        event.accepted = true;
      }
    }
  }

  // Show settings on Super+, hotkey
  Shortcut {
    sequences: ["Super+comma"]
    onActivated: settingsWindow.visible = !settingsWindow.visible
  }
}
