pragma Singleton
import QtQuick
import Quickshell.Io
import "."

// Wallpaper, colors and avatar a user's shell synced for the greeter, in
// <userThemesDir>/<user>/: theme.json ({ "wallpaper": file, "colors": {…} })
// and the files it names. Empty when the user synced nothing.
QtObject {
    id: root

    readonly property string dir:
        Config.userThemes && Selection.userInfo ? Config.userThemesDir + "/" + Selection.user : ""

    property var _data: ({})
    readonly property var    colors:    _data.colors ?? ({})
    readonly property string wallpaper: _data.wallpaper ? dir + "/" + _data.wallpaper : ""
    readonly property string avatar:    _data.avatar ? dir + "/" + _data.avatar : ""

    property FileView _file: FileView {
        path: root.dir !== "" ? root.dir + "/theme.json" : ""
        printErrors: false
        onLoaded: {
            try { root._data = JSON.parse(text()) }
            catch (e) { root._data = {} }
        }
        onLoadFailed: root._data = {}
        onPathChanged: if (path === "") root._data = {}
    }
}
