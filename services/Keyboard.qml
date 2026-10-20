pragma Singleton
import QtQuick
import Quickshell.Io

// Layout and Caps Lock of the main keyboard, from Hyprland. Unavailable on
// other compositors (and while testing elsewhere).
QtObject {
    id: root

    property bool   available: false
    property string layout: ""        // active keymap, e.g. "French (AZERTY)"
    property bool   multiple: false   // several layouts configured
    property bool   capsLock: false

    function next() {
        _switch.running = false
        _switch.running = true
    }
    function refresh() {
        if (!_probe.running) _probe.running = true
    }

    property Process _probe: Process {
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let d
                try { d = JSON.parse(text) } catch (e) { root.available = false; return }
                const kbs = d.keyboards ?? []
                const kb = kbs.find(k => k.main) ?? kbs[0]
                if (!kb) { root.available = false; return }
                root.available = true
                root.layout = kb.active_keymap ?? ""
                root.multiple = ("" + (kb.layout ?? "")).indexOf(",") >= 0
                root.capsLock = kb.capsLock === true
            }
        }
    }
    property Process _switch: Process {
        command: ["hyprctl", "switchxkblayout", "all", "next"]
        onExited: root.refresh()
    }
    property Timer _poll: Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
