pragma Singleton
import QtQuick
import Quickshell

// logind lets the active seat's session power the machine off without a
// password, the greeter's included.
QtObject {
    readonly property var actions: [
        { id: "suspend",  label: "Suspend",   icon: "󰒲", confirm: "Suspend the computer?" },
        { id: "reboot",   label: "Restart",   icon: "󰜉", confirm: "Restart the computer?" },
        { id: "poweroff", label: "Power off", icon: "󰐥", confirm: "Power off the computer?" }
    ]

    function run(id) { Quickshell.execDetached(["systemctl", id]) }
}
