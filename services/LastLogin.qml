pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// What the greeter remembers between logins: the last user, and each user's
// last session. Kept in the greeter user's state directory.
QtObject {
    id: root

    readonly property string dir:
        (Quickshell.env("XDG_STATE_HOME") || ((Quickshell.env("HOME") || "/tmp") + "/.local/state")) + "/scottbass3-greeter"

    property bool   loaded: false
    property string lastUser: ""
    property var    sessions: ({})   // user → session id

    function sessionFor(user) { return sessions[user] ?? "" }

    function remember(user, session) {
        lastUser = user
        const s = Object.assign({}, sessions)
        s[user] = session
        sessions = s
        _file.setText(JSON.stringify({ lastUser: lastUser, sessions: sessions }, null, 2) + "\n")
    }

    property Process _mkdir: Process {
        command: ["mkdir", "-p", root.dir]
        running: true
    }

    property FileView _file: FileView {
        path: root.dir + "/state.json"
        blockLoading: true
        printErrors: false
        atomicWrites: true
        // The greeter quits right after a login: the write must be done by then.
        blockWrites: true
        onLoaded: {
            try {
                const d = JSON.parse(text())
                root.lastUser = d.lastUser ?? ""
                root.sessions = d.sessions ?? {}
            } catch (e) {}
            root.loaded = true
        }
        onLoadFailed: root.loaded = true
    }
}
