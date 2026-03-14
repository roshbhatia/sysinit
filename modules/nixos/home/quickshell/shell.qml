import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar.Bar {
            screen: modelData
        }
    }
}
