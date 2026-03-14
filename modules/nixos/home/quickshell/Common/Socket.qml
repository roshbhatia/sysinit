import QtQuick
import Quickshell.Io

Item {
    id: root

    property string socketPath: ""
    property bool connected: false

    signal messageReceived(string message)
    signal connectedChanged()

    function send(data) {
        if (socket.connected) {
            socket.write(data + "\n")
            socket.flush()
        }
    }

    function connectToSocket() {
        if (socketPath !== "") {
            socket.path = socketPath
            socket.connect()
        }
    }

    property int _retryDelay: 1000
    property int _maxRetryDelay: 30000

    Socket {
        id: socket

        onConnected: {
            root.connected = true
            root._retryDelay = 1000
        }

        onDisconnected: {
            root.connected = false
            retryTimer.interval = root._retryDelay
            retryTimer.start()
            root._retryDelay = Math.min(root._retryDelay * 2, root._maxRetryDelay)
        }

        parser: SplitParser {
            onRead: data => root.messageReceived(data)
        }
    }

    Timer {
        id: retryTimer
        repeat: false
        onTriggered: root.connectToSocket()
    }

    Component.onCompleted: connectToSocket()
}
