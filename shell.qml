import QtQuick
import Quickshell
import "services"

// scottbass3-greeter: a greetd greeter with the scottbass3-shell lock screen's
// look. Run by hypr/greeter.lua inside a dedicated Hyprland session.
ShellRoot {
    Variants {
        model: Quickshell.screens
        GreeterSurface {}
    }
}
