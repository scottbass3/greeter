pragma Singleton
import QtQuick
import Quickshell.Io
import "."

// Regular users from /etc/passwd: UID in the login.defs range and a real
// shell, minus Config.hiddenUsers.
QtObject {
    id: root

    property var  _all: []
    property bool loaded: false
    readonly property var users: _all.filter(u => u.uid >= System.uidMin && u.uid <= System.uidMax
                                              && Config.hiddenUsers.indexOf(u.name) < 0)

    function byName(name) { return users.find(u => u.name === name) ?? null }

    property FileView _passwd: FileView {
        path: "/etc/passwd"
        blockLoading: true
        onLoaded: {
            const list = []
            for (const line of text().split("\n")) {
                const f = line.split(":")
                if (f.length < 7) continue
                const shell = f[6].trim()
                if (shell === "" || /(nologin|false)$/.test(shell)) continue
                const gecos = f[4].split(",")[0].trim()
                list.push({ name: f[0], uid: parseInt(f[2]), home: f[5], displayName: gecos || f[0] })
            }
            list.sort((a, b) => a.uid - b.uid)
            root._all = list
            root.loaded = true
        }
        onLoadFailed: root.loaded = true
    }
}
