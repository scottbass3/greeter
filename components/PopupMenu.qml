import QtQuick
import QtQuick.Layouts
import "../theme"

// A list of choices drawn over the greeter: [{ label, icon, selected, run }].
// The parent places it and sets `open`.
Rectangle {
    id: root

    property var  items: []
    property bool open: false
    signal closed()

    visible: open
    width: 280
    height: _col.implicitHeight + 12
    radius: Theme.radius
    color: Theme.surfaceContainerHigh
    border.width: 1
    border.color: Theme.outlineVariant
    z: 100

    ColumnLayout {
        id: _col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
        spacing: 2
        Repeater {
            model: root.items
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.radius - 6
                color: _hov.containsMouse ? Theme.secondaryContainer : "transparent"
                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    spacing: 10
                    Text {
                        text: modelData.icon ?? ""
                        visible: text !== ""
                        color: Theme.surfaceVariantText
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        elide: Text.ElideRight
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                    }
                    Text {
                        visible: modelData.selected === true
                        text: "󰄬"
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }
                }
                MouseArea {
                    id: _hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.closed(); modelData.run() }
                }
            }
        }
    }
}
