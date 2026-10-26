pragma Singleton
import QtQuick
import Quickshell.Io
import "."

// Wallpaper, colors and avatar a user's shell synced for the greeter, in
// <userThemesDir>/<user>/: theme.json ({ "wallpaper": file, "avatar": file,
// "colors": {…} }) and the files it names. The directory is only trusted when
// that user owns it, as anyone can create entries in userThemesDir.
QtObject {
    id: root

    readonly property string dir:
        Config.userThemes && Selection.userInfo ? Config.userThemesDir + "/" + Selection.user : ""

    property var _data: ({})
    property bool _trusted: false
    readonly property var    colors:    _trusted ? (_data.colors ?? {}) : ({})
    readonly property string wallpaper: _trusted && _data.wallpaper ? dir + "/" + _data.wallpaper : ""
    readonly property string avatar:    _trusted && _data.avatar ? dir + "/" + _data.avatar : ""

    onDirChanged: {
        _trusted = false
        _data = {}
        if (dir === "") return
        _owner.command = ["stat", "-c", "%u", dir]
        _owner.running = false
        _owner.running = true
    }

    property Process _owner: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._owner.command[3] !== root.dir) return   // the user changed meanwhile
                const uid = parseInt(text.trim())
                root._trusted = !isNaN(uid) && uid === Selection.userInfo?.uid
                if (root._trusted) root._file.reload()
            }
        }
    }

    property FileView _file: FileView {
        path: root._trusted ? root.dir + "/theme.json" : ""
        printErrors: false
        onLoaded: {
            try { root._data = JSON.parse(text()) }
            catch (e) { root._data = {} }
        }
        onLoadFailed: root._data = {}
    }
}
