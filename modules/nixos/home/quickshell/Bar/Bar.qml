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

            implicitHeight: Theme.barHeight
            color: Theme.bg

            Item {
                anchors.fill: parent
                anchors.leftMargin: Theme.barPadH
                anchors.rightMargin: Theme.barPadH

                // Left section
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.sectionSpacing

                    Logo {}
                    Separator {}
                    FrontApp {}
                }

                // Center section
                Row {
                    anchors.centerIn: parent
                    spacing: 0

                    Niri { screen: bar.screen }
                }

                // Right section
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.sectionSpacing

                    DateTime {}
                    Separator {}
                    Volume {}
                }
            }
        }
    }
}
