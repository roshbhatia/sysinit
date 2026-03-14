import QtQuick
import QtQuick.Layouts
import qs.Theme
import qs.Common

RowLayout {
    spacing: 6

    property string localTime: ""
    property string utcTime: ""

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            // 12-hour format
            var h = now.getHours()
            var ampm = h >= 12 ? "PM" : "AM"
            h = h % 12
            if (h === 0) h = 12
            var m = now.getMinutes().toString().padStart(2, '0')
            localTime = h + ":" + m + " " + ampm

            // UTC
            var uh = now.getUTCHours().toString().padStart(2, '0')
            var um = now.getUTCMinutes().toString().padStart(2, '0')
            utcTime = uh + ":" + um + " UTC"
        }
    }

    // Local time icon
    Text {
        text: "\udb80\udc31" // 󰀱
        color: Theme.text
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        verticalAlignment: Text.AlignVCenter
    }

    DefaultText {
        text: localTime
        font.bold: true
        verticalAlignment: Text.AlignVCenter
    }

    DefaultText {
        text: "•"
        color: Theme.textMuted
        verticalAlignment: Text.AlignVCenter
    }

    // UTC icon
    Text {
        text: "\udb80\udd9f" // 󰖟
        color: Theme.textMuted
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
        verticalAlignment: Text.AlignVCenter
    }

    DefaultText {
        text: utcTime
        color: Theme.textMuted
        verticalAlignment: Text.AlignVCenter
    }
}
