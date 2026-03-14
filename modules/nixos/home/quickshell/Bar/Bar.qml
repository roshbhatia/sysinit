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

            implicitHeight: 32
            color: Theme.bg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 0

                // === LEFT ===
                RowLayout {
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    spacing: 10

                    Logo {}
                    Separator {}
                    FrontApp {}

                    Separator { visible: music.visible }
                    Music { id: music }
                }

                // === CENTER SPACER ===
                Item { Layout.fillWidth: true }

                // === CENTER ===
                RowLayout {
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    spacing: 0

                    Niri { screen: bar.screen }
                }

                // === CENTER SPACER ===
                Item { Layout.fillWidth: true }

                // === RIGHT ===
                RowLayout {
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: 10

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
