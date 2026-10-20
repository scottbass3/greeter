import QtQuick
import Quickshell.Widgets
import "../theme"

// A user's picture: the one their shell synced, else AccountsService's, else
// their initials.
ClippingRectangle {
    id: root

    property var    sources: []
    property string name: ""

    radius: width / 2
    color: Qt.rgba(1, 1, 1, 0.12)

    property int _at: 0
    onSourcesChanged: _at = 0

    Image {
        id: _img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: root.width * 2
        source: root._at < root.sources.length ? "file://" + root.sources[root._at] : ""
        visible: status === Image.Ready
        onStatusChanged: if (status === Image.Error) root._at++
    }
    Text {
        anchors.centerIn: parent
        visible: _img.status !== Image.Ready
        text: root.name !== "" ? root.name.split(/\s+/).map(w => w[0]).join("").slice(0, 2).toUpperCase() : "󰀄"
        color: "white"
        font.family: Theme.fontFamily
        font.pixelSize: root.name !== "" ? root.width * 0.38 : root.width * 0.66
        font.weight: Font.Medium
    }
}
