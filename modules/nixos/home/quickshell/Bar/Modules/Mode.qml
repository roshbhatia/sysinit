import QtQuick
import Quickshell
import Quickshell.Io
import qs.Theme

Text {
    id: modeDisplay
    height: Theme.barHeight

    property string mode: "MAIN"
    property string modePath: Quickshell.env("HOME") + "/.cache/niri-mode"

    // Only show when not MAIN
    visible: mode !== "MAIN"
    text: mode
    color: mode === "MOVE" ? Theme.yellow : Theme.red
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
    verticalAlignment: Text.AlignVCenter

    FileView {
        id: modeFile
        path: modeDisplay.modePath

        onTextChanged: {
            if (text) {
                var m = text.trim()
                if (m !== "") modeDisplay.mode = m
            }
        }
    }
}
