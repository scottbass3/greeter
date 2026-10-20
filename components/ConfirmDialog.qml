import QtQuick
import QtQuick.Layouts
import "../theme"

// A centered question with Cancel and a confirm button, over a scrim.
// Enter confirms and Esc cancels; the parent routes those keys.
Rectangle {
    id: root

    property bool   open: false
    property string icon: ""
    property string title: ""
    property string confirmLabel: "OK"
    signal confirmed()
    signal canceled()

    visible: open
    color: Qt.rgba(0, 0, 0, 0.45)
    z: 200

    MouseArea { anchors.fill: parent; onClicked: root.canceled() }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 60, 380)
        height: _col.implicitHeight + 44
        radius: Theme.radius + 4
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.outlineVariant
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: _col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 22 }
            spacing: 18
            RowLayout {
                spacing: 12
                Text {
                    text: root.icon
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                }
                Text {
                    Layout.fillWidth: true
                    text: root.title
                    wrapMode: Text.WordWrap
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.DemiBold
                }
            }
            Text {
                Layout.fillWidth: true
                text: "Enter confirms, Esc cancels."
                color: Theme.surfaceVariantText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8
                DialogButton { label: "Cancel"; onClicked: root.canceled() }
                DialogButton { label: root.confirmLabel; strong: true; onClicked: root.confirmed() }
            }
        }
    }

    component DialogButton: Rectangle {
        id: db
        property string label: ""
        property bool strong: false
        signal clicked()
        implicitWidth: _t.implicitWidth + 32
        implicitHeight: 38
        radius: 19
        color: strong ? (_m.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
             : (_m.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
        border.width: strong ? 0 : 1
        border.color: Theme.outlineVariant
        Text {
            id: _t
            anchors.centerIn: parent
            text: db.label
            color: db.strong ? Theme.primaryText : Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
        }
        MouseArea {
            id: _m
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: db.clicked()
        }
    }
}
