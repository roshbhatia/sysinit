import QtQuick
import Quickshell.Io
import qs.Theme
import qs.Common

DefaultText {
    id: modeDisplay

    property string mode: "MAIN"

    text: mode
    color: mode === "MOVE" ? Theme.yellow :
           mode === "LOCKED" ? Theme.red :
           Theme.text
    font.bold: mode !== "MAIN"
    verticalAlignment: Text.AlignVCenter

    FileView {
        id: modeFile
        path: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.cache/niri-mode")

        onTextChanged: {
            var m = text.trim()
            if (m !== "") {
                modeDisplay.mode = m
            }
        }
    }
}
