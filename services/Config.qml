pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// System configuration: /etc/scottbass3-greeter/config.json (or
// $SCOTTBASS3_GREETER_CONFIG). Every key is optional; see config.example.json.
QtObject {
    id: root

    readonly property string path:
        Quickshell.env("SCOTTBASS3_GREETER_CONFIG") || "/etc/scottbass3-greeter/config.json"

    property var _data: ({})

    readonly property string wallpaper:      _data.wallpaper ?? ""
    readonly property string font:           _data.font ?? "JetBrainsMono Nerd Font"
    readonly property var    colors:         _data.colors ?? ({})
    readonly property string locale:         _data.locale ?? ""
    readonly property bool   clock24h:       _data.clock24h ?? true
    readonly property var    hiddenUsers:    _data.hiddenUsers ?? []
    readonly property string defaultSession: _data.defaultSession ?? ""
    // Directories of session .desktop files; X11 ones have "xsessions" in their path.
    readonly property var    sessionDirs:    _data.sessionDirs ?? ["/usr/share/wayland-sessions", "/usr/share/xsessions"]
    // Wallpaper and colors synced by each user's shell (see README).
    readonly property bool   userThemes:     _data.userThemes ?? true
    readonly property string userThemesDir:  _data.userThemesDir ?? "/var/lib/scottbass3-greeter/users"

    property FileView _file: FileView {
        path: root.path
        blockLoading: true
        printErrors: false
        onLoaded: {
            try { root._data = JSON.parse(text()) }
            catch (e) { console.warn("scottbass3-greeter: invalid " + root.path + ": " + e) }
        }
    }
}
