pragma Singleton
import QtQuick

QtObject {
    // Gruvbox Dark Hard
    readonly property color bg: "#1d2021"
    readonly property color bgAlt: "#282828"
    readonly property color surface: "#3c3836"
    readonly property color border: "#504945"
    readonly property color text: "#ebdbb2"
    readonly property color textMuted: "#928374"
    readonly property color textDim: "#a89984"

    // Accent colors
    readonly property color red: "#fb4934"
    readonly property color green: "#b8bb26"
    readonly property color yellow: "#fabd2f"
    readonly property color blue: "#83a598"
    readonly property color purple: "#d3869b"
    readonly property color aqua: "#8ec07c"
    readonly property color orange: "#fe8019"

    // Workspace dot accent cycle
    readonly property var dotColors: ["#fe8019", "#fabd2f", "#8ec07c", "#b8bb26"]

    // Fonts
    readonly property string fontFamily: "IoskeleyMono"
    readonly property string iconFont: "Symbols Nerd Font Mono"
    readonly property int fontSize: 12
    readonly property int iconSize: 13

    // Bar
    readonly property int barHeight: 30
    readonly property int barPadH: 14
    readonly property int sectionSpacing: 8
}
