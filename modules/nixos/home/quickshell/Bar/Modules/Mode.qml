import QtQuick
import Quickshell
import Quickshell.Io
import qs.Theme
import qs.Common

DefaultText {
    id: modeDisplay

    property string mode: "MAIN"
    property string modePath: Quickshell.env("HOME") + "/.cache/niri-mode"

    text: mode
    color: mode === "MOVE" ? Theme.yellow :
           mode === "LOCKED" ? Theme.red :
           Theme.text
    font.bold: mode !== "MAIN"
    verticalAlignment: Text.AlignVCenter

    FileView {
        id: modeFile
        path: modeDisplay.modePath

        onTextChanged: {
            if (text) {
                var m = text.trim()
                if (m !== "") {
                    modeDisplay.mode = m
                }
            }
        }
    }
}
