import QtQuick
import qs.Theme

Row {
    spacing: 6
    height: Theme.barHeight

    property string localTime: ""
    property string utcTime: ""

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            var h = now.getHours()
            var ampm = h >= 12 ? "PM" : "AM"
            h = h % 12
            if (h === 0) h = 12
            var m = now.getMinutes().toString().padStart(2, '0')
            localTime = h + ":" + m + " " + ampm

            var uh = now.getUTCHours().toString().padStart(2, '0')
            var um = now.getUTCMinutes().toString().padStart(2, '0')
            utcTime = uh + ":" + um
        }
    }

    Text {
        text: localTime
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: "·"
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: utcTime + " UTC"
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        anchors.verticalCenter: parent.verticalCenter
    }
}
