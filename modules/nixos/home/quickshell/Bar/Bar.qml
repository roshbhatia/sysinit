import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Theme
import qs.Bar.Modules

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            property var modelData

            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 36
            color: Theme.bg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 0

                // === LEFT ===
                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing: 12

                    Logo {}

                    Separator {}

                    FrontApp {}

                    Separator {
                        visible: music.visible
                    }

                    Music {
                        id: music
                    }
                }

                // === CENTER SPACER ===
                Item { Layout.fillWidth: true }

                // === CENTER (workspace dots) ===
                Niri {
                    screen: bar.screen
                }

                // === CENTER SPACER ===
                Item { Layout.fillWidth: true }

                // === RIGHT ===
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 12

                    DateTime {}

                    Separator {}

                    Battery {}

                    Separator {}

                    Volume {}
                }
            }
        }
    }
}
