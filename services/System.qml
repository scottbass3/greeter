pragma Singleton
import QtQuick
import Quickshell.Io

// System facts the greeter needs: the locale for dates (greetd starts it with
// a bare environment) and the range of regular users' UIDs.
QtObject {
    id: root

    property string locale: ""
    property int    uidMin: 1000
    property int    uidMax: 60000

    property FileView _localeConf: FileView {
        path: "/etc/locale.conf"
        blockLoading: true
        printErrors: false
        // Dates follow LC_TIME when set, like in the user's session.
        onLoaded: {
            const m = text().match(/^LC_TIME=["']?([^"'\s.]+)/m) ?? text().match(/^LANG=["']?([^"'\s.]+)/m)
            if (m) root.locale = m[1]
        }
    }

    property FileView _loginDefs: FileView {
        path: "/etc/login.defs"
        blockLoading: true
        printErrors: false
        onLoaded: {
            const min = text().match(/^UID_MIN\s+(\d+)/m)
            const max = text().match(/^UID_MAX\s+(\d+)/m)
            if (min) root.uidMin = parseInt(min[1])
            if (max) root.uidMax = parseInt(max[1])
        }
    }
}
