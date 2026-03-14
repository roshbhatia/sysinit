import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Theme
import qs.Common

RowLayout {
    id: batteryWidget
    spacing: 6

    property var battery: UPower.displayDevice
    property real percentage: battery ? battery.percentage : 0
    property bool charging: battery ? (battery.state === UPowerDeviceState.Charging) : false
    property bool hasBattery: battery ? battery.isPresent : false

    visible: hasBattery

    property string icon: {
        if (charging) return "\udb80\udc85"
        if (percentage >= 80) return "\udb80\udc81"
        if (percentage >= 60) return "\udb80\udc7f"
        if (percentage >= 40) return "\udb80\udc7d"
        if (percentage >= 20) return "\udb80\udc7b"
        return "\udb80\udc7a"
    }

    property color batteryColor: {
        if (charging) return Theme.green
        if (percentage >= 80) return Theme.green
        if (percentage >= 60) return Theme.text
        if (percentage >= 40) return Theme.yellow
        if (percentage >= 20) return Theme.orange
        return Theme.red
    }

    Text {
        text: batteryWidget.icon
        color: batteryWidget.batteryColor
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        verticalAlignment: Text.AlignVCenter
    }

    DefaultText {
        text: Math.round(batteryWidget.percentage) + "%"
        color: batteryWidget.batteryColor
        verticalAlignment: Text.AlignVCenter
    }
}
