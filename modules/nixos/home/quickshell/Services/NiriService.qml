pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
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
        actionProcess.command = ["niri", "msg", "action", "focus-workspace", index.toString()]
        actionProcess.running = true
    }

    // Internal
    property var _workspaceMap: ({})
    property var _windowMap: ({})

    // Connect to niri event stream
    Process {
        id: eventStream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    var event = JSON.parse(data)
                    root._handleEvent(event)
                } catch (e) {
                    // Skip unparseable lines
                }
            }
        }

        onExited: (code, status) => {
            // Restart after a delay if it exits
            restartTimer.start()
        }
    }

    // Action process for sending commands
    Process {
        id: actionProcess
        running: false
    }

    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: eventStream.running = true
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
            // Update workspace states
            var updated = []
            for (var i = 0; i < allWorkspaces.length; i++) {
                var w = Object.assign({}, allWorkspaces[i])
                if (w.id === ws.id) {
                    w.is_active = ws.is_active
                    if (ws.focused) {
                        w.is_focused = true
                        currentOutput = w.output || ""
                    }
                } else if (ws.focused) {
                    w.is_focused = false
                }
                updated.push(w)
            }
            allWorkspaces = updated
        } else if (event.WorkspaceActiveWindowChanged) {
            var waw = event.WorkspaceActiveWindowChanged
            if (waw.id === focusedWorkspaceId) {
                focusedWindowTitle = waw.title || ""
                focusedWindowAppId = waw.app_id || ""
            }
        } else if (event.WindowsChanged) {
            _updateWindows(event.WindowsChanged.windows)
        } else if (event.WindowOpenedOrChanged) {
            var win = event.WindowOpenedOrChanged.window
            _windowMap[win.id] = win
            if (win.is_focused) {
                focusedWindowTitle = win.title || ""
                focusedWindowAppId = win.app_id || ""
            }
        } else if (event.WindowClosed) {
            delete _windowMap[event.WindowClosed.id]
        } else if (event.WindowFocusChanged) {
            var wfc = event.WindowFocusChanged
            if (wfc.id !== undefined && wfc.id !== null) {
                var focusedWin = _windowMap[wfc.id]
                if (focusedWin) {
                    focusedWindowTitle = focusedWin.title || ""
                    focusedWindowAppId = focusedWin.app_id || ""
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
