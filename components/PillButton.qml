import QtQuick
import QtQuick.Controls
import "../theme"

// A translucent pill over the wallpaper: an icon, optionally a label.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string tip: ""
    property bool   highlighted: false
    signal clicked()

    implicitWidth: label !== "" ? _row.implicitWidth + 28 : 44
    implicitHeight: 44
    radius: height / 2
    color: _mouse.containsMouse || highlighted ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: _row
        anchors.centerIn: parent
        spacing: 8
        Text {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: "white"
            font.family: Theme.fontFamily
            font.pixelSize: 18
        }
        Text {
            visible: root.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: "white"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMd
        }
    }
    MouseArea {
        id: _mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
    ToolTip.visible: _mouse.containsMouse && tip !== ""
    ToolTip.text: tip
    ToolTip.delay: 500
}
