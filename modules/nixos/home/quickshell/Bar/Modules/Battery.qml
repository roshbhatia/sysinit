import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Theme

Row {
    id: bat
    spacing: 5
    height: Theme.barHeight

    property var battery: UPower.displayDevice
    property real pct: battery ? battery.percentage : 0
    property bool charging: battery ? (battery.state === UPowerDeviceState.Charging) : false
    property bool present: battery ? battery.isPresent : false

    visible: present

    property string icon: {
        if (charging) return "\udb80\udc85"
        if (pct >= 80) return "\udb80\udc81"
        if (pct >= 60) return "\udb80\udc7f"
        if (pct >= 40) return "\udb80\udc7d"
        if (pct >= 20) return "\udb80\udc7b"
        return "\udb80\udc7a"
    }

    property color col: {
        if (charging) return Theme.green
        if (pct >= 80) return Theme.green
        if (pct >= 60) return Theme.text
        if (pct >= 40) return Theme.yellow
        if (pct >= 20) return Theme.orange
        return Theme.red
    }

    Text {
        text: bat.icon
        color: bat.col
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: Math.round(bat.pct) + "%"
        color: bat.col
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        anchors.verticalCenter: parent.verticalCenter
    }
}
