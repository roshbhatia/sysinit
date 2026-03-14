pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Item {
    id: root

    // Public state
    property var allWorkspaces: []
    property int focusedWorkspaceId: -1
    property int focusedWorkspaceIndex: -1
    property string focusedWindowTitle: ""
    property string focusedWindowAppId: ""
    property string currentOutput: ""

    // Actions
    function switchToWorkspace(index) {
        socket.send(JSON.stringify({"Action": {"FocusWorkspace": {"reference": {"Index": index}}}}))
    }

    function focusWindow(windowId) {
        socket.send(JSON.stringify({"Action": {"FocusWindow": {"id": windowId}}}))
    }

    // Internal
    property var _workspaceMap: ({})
    property var _windowMap: ({})

    Socket {
        id: socket
        socketPath: Quickshell.env("NIRI_SOCKET") || ""

        onMessageReceived: function(message) {
            try {
                var event = JSON.parse(message)
                root._handleEvent(event)
            } catch (e) {
                console.warn("NiriService: Failed to parse event:", e)
            }
        }

        onConnectedChanged: {
            if (connected) {
                socket.send('"EventStream"')
            }
        }
    }

    function _handleEvent(event) {
        if (event.WorkspacesChanged) {
            _updateWorkspaces(event.WorkspacesChanged.workspaces)
        } else if (event.WorkspaceActivated) {
            var ws = event.WorkspaceActivated
            if (ws.focused) {
                focusedWorkspaceId = ws.id
                _updateFocusedIndex()
            }
            // Update is_active flag
            for (var i = 0; i < allWorkspaces.length; i++) {
                if (allWorkspaces[i].id === ws.id) {
                    allWorkspaces[i].is_active = ws.is_active
                    if (ws.focused) {
                        allWorkspaces[i].is_focused = true
                        currentOutput = allWorkspaces[i].output || ""
                    }
                } else if (ws.focused) {
                    allWorkspaces[i].is_focused = false
                }
            }
            allWorkspacesChanged()
        } else if (event.WorkspaceActiveWindowChanged) {
            var waw = event.WorkspaceActiveWindowChanged
            if (waw.id === focusedWorkspaceId) {
                focusedWindowTitle = waw.title || ""
                focusedWindowAppId = waw.app_id || ""
            }
        } else if (event.WindowsChanged) {
            _updateWindows(event.WindowsChanged.windows)
        } else if (event.WindowOpenedOrChanged) {
            var w = event.WindowOpenedOrChanged.window
            _windowMap[w.id] = w
            if (w.is_focused) {
                focusedWindowTitle = w.title || ""
                focusedWindowAppId = w.app_id || ""
            }
        } else if (event.WindowClosed) {
            delete _windowMap[event.WindowClosed.id]
        } else if (event.WindowFocusChanged) {
            var wfc = event.WindowFocusChanged
            if (wfc.id !== undefined && wfc.id !== null) {
                var win = _windowMap[wfc.id]
                if (win) {
                    focusedWindowTitle = win.title || ""
                    focusedWindowAppId = win.app_id || ""
                }
            } else {
                focusedWindowTitle = ""
                focusedWindowAppId = ""
            }
        }
    }

    function _updateWorkspaces(workspaces) {
        var sorted = workspaces.sort(function(a, b) {
            if (a.output !== b.output) return a.output < b.output ? -1 : 1
            return a.idx - b.idx
        })

        _workspaceMap = {}
        for (var i = 0; i < sorted.length; i++) {
            _workspaceMap[sorted[i].id] = sorted[i]
            if (sorted[i].is_focused) {
                focusedWorkspaceId = sorted[i].id
                focusedWorkspaceIndex = sorted[i].idx
                currentOutput = sorted[i].output || ""
            }
        }
        allWorkspaces = sorted
    }

    function _updateWindows(windows) {
        _windowMap = {}
        for (var i = 0; i < windows.length; i++) {
            _windowMap[windows[i].id] = windows[i]
            if (windows[i].is_focused) {
                focusedWindowTitle = windows[i].title || ""
                focusedWindowAppId = windows[i].app_id || ""
            }
        }
    }

    function _updateFocusedIndex() {
        for (var i = 0; i < allWorkspaces.length; i++) {
            if (allWorkspaces[i].id === focusedWorkspaceId) {
                focusedWorkspaceIndex = allWorkspaces[i].idx
                break
            }
        }
    }
}
