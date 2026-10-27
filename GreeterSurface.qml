import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "theme"
import "services"
import "components"

// One screen of the greeter. Idle: wallpaper, clock and date. A click or a key
// blurs the wallpaper and shows the login prompt, on the focused screen only.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "scottbass3-greeter"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "black"

    // The prompt follows Hyprland's focused monitor, else the first screen.
    readonly property bool active: {
        const focused = Hyprland.focusedMonitor?.name ?? ""
        if (focused !== "") return focused === modelData.name
        return (Quickshell.screens[0]?.name ?? "") === modelData.name
    }
    onActiveChanged: if (!active) hidePrompt()

    property bool showPrompt: false
    property bool showPassword: false
    property var  now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: win.now = new Date() }

    readonly property string _timeFormat: Config.clock24h ? "HH:mm" : "h:mm AP"
    readonly property string wallpaper: UserTheme.wallpaper !== "" ? UserTheme.wallpaper : Config.wallpaper

    function reveal() {
        if (!active) return
        showPrompt = true
        _focusInput()
    }
    function hidePrompt() {
        showPrompt = false
        _menu = ""
        _power = ""
        _field.text = ""
        Auth.cancel()
        _keys.forceActiveFocus()
    }
    function _focusInput() {
        Qt.callLater(() => {
            if (Selection.manual && Selection.typedUser.trim() === "") _userField.forceActiveFocus()
            else _field.forceActiveFocus()
        })
    }
    function _submit() {
        if (Auth.busy) return
        if (Auth.prompt !== "") Auth.answer(_field.text)
        else Auth.login(_field.text)
        _field.text = ""
    }

    // Shortcuts shared by both input fields. Returns true when handled.
    function _shortcut(e) {
        const ctrl = e.modifiers & Qt.ControlModifier
        if (_power !== "") {
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { const id = _power; _power = ""; Power.run(id) }
            else if (e.key === Qt.Key_Escape) _power = ""
            return true
        }
        if (e.key === Qt.Key_Escape) {
            if (_menu !== "") _menu = ""
            else if (Auth.prompt !== "") Auth.cancel()
            else hidePrompt()
            return true
        }
        if (ctrl && !Auth.busy && (e.key === Qt.Key_Left || e.key === Qt.Key_Right)) {
            Selection.cycleUser(e.key === Qt.Key_Left ? -1 : 1)
            _focusInput()
            return true
        }
        if (ctrl && (e.key === Qt.Key_Up || e.key === Qt.Key_Down)) {
            Selection.cycleSession(e.key === Qt.Key_Up ? -1 : 1)
            return true
        }
        return false
    }

    Connections {
        target: Auth
        function onFailed() { _shake.restart(); win._focusInput() }
    }

    // ── Popups: "users" | "sessions" menus, power confirmation ───────────────
    property string _menu: ""
    property string _power: ""
    readonly property var _powerAction: Power.actions.find(a => a.id === _power) ?? null

    readonly property var _userItems: Users.users.map(u => ({
        label: u.displayName !== u.name ? u.displayName + "  (" + u.name + ")" : u.name,
        icon: "󰀄",
        selected: !Selection.manual && Selection.user === u.name,
        run: () => { Selection.selectUser(u.name); win._focusInput() }
    })).concat([{
        label: "Other user…",
        icon: "󰀈",
        selected: Selection.manual,
        run: () => { Selection.selectManual(); win._focusInput() }
    }])
    readonly property var _sessionItems: Sessions.sessions.map(s => ({
        label: s.name,
        icon: "󰍹",
        selected: Selection.session === s.id,
        run: () => { Selection.session = s.id; win._focusInput() }
    }))

    // ── Wallpaper ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.surface }
            GradientStop { position: 1.0; color: Theme.secondaryContainer }
        }
    }
    Image {
        id: _wall
        anchors.fill: parent
        source: win.wallpaper !== "" ? "file://" + win.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
    }
    MultiEffect {
        anchors.fill: parent
        source: _wall
        visible: _wall.visible
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        autoPaddingEnabled: false
        opacity: win.showPrompt ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: win.showPrompt ? 0.45 : 0.15
        Behavior on opacity { NumberAnimation { duration: 280 } }
    }

    // ── Idle: clock and date ─────────────────────────────────────────────────
    Column {
        anchors { left: parent.left; leftMargin: 80; verticalCenter: parent.verticalCenter }
        opacity: win.showPrompt ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 260 } }
        Text {
            text: win.now.toLocaleTimeString(Theme.locale, win._timeFormat)
            color: "white"
            font.family: Theme.fontFamily
            font.pixelSize: 120
            font.weight: Font.Bold
        }
        Text {
            text: win.now.toLocaleDateString(Theme.locale, "dddd, d MMMM yyyy")
            color: "white"
            opacity: 0.85
            font.family: Theme.fontFamily
            font.pixelSize: 26
        }
    }
    Text {
        visible: win.active
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 48 }
        opacity: win.showPrompt ? 0 : 0.75
        Behavior on opacity { NumberAnimation { duration: 260 } }
        text: "Press a key or click to sign in"
        color: "white"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMd
    }

    // ── Prompt ───────────────────────────────────────────────────────────────
    Column {
        id: _prompt
        anchors.centerIn: parent
        spacing: 16
        opacity: win.showPrompt ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        transform: Translate { id: _shakeX }

        SequentialAnimation {
            id: _shake
            NumberAnimation { target: _shakeX; property: "x"; to: -14; duration: 50 }
            NumberAnimation { target: _shakeX; property: "x"; to: 12; duration: 70 }
            NumberAnimation { target: _shakeX; property: "x"; to: -8; duration: 60 }
            NumberAnimation { target: _shakeX; property: "x"; to: 0; duration: 50 }
        }

        // Avatar between previous/next user arrows
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24
            Arrow { text: "󰅁"; tip: "Previous user (Ctrl+←)"; onClicked: { Selection.cycleUser(-1); win._focusInput() } }
            Avatar {
                width: 104; height: 104
                name: Selection.manual ? "" : (Selection.userInfo?.displayName ?? "")
                sources: Selection.manual ? [] : [UserTheme.avatar, "/var/lib/AccountsService/icons/" + Selection.user].filter(s => s !== "")
            }
            Arrow { text: "󰅂"; tip: "Next user (Ctrl+→)"; onClicked: { Selection.cycleUser(1); win._focusInput() } }
        }

        // User name: click to pick from the list. "Other user" types it.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300
            height: 34
            Text {
                visible: !Selection.manual
                anchors.centerIn: parent
                text: (Selection.userInfo?.displayName ?? Selection.user) + "  󰅀"
                color: "white"
                font.family: Theme.fontFamily
                font.pixelSize: 22
                font.weight: Font.Medium
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win._menu = win._menu === "users" ? "" : "users"
                }
            }
            Rectangle {
                visible: Selection.manual
                anchors.fill: parent
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.12)
                border.width: _userField.activeFocus ? 1 : 0
                border.color: Qt.rgba(1, 1, 1, 0.35)
                TextInput {
                    id: _userField
                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    color: "white"
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    clip: true
                    enabled: !Auth.busy
                    text: Selection.typedUser
                    onTextChanged: if (text !== Selection.typedUser) Selection.typedUser = text
                    onAccepted: _field.forceActiveFocus()
                    KeyNavigation.tab: _field
                    Keys.onPressed: (e) => { if (win._shortcut(e)) e.accepted = true }
                    Text {
                        anchors.centerIn: parent
                        visible: _userField.text === ""
                        text: "User name"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font: _userField.font
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: win.now.toLocaleTimeString(Theme.locale, win._timeFormat)
            color: "white"
            opacity: 0.9
            font.family: Theme.fontFamily
            font.pixelSize: 30
            font.weight: Font.Medium
        }

        // Password, or PAM's follow-up question
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 46
            radius: 23
            color: Qt.rgba(1, 1, 1, 0.12)
            border.width: Auth.busy ? 0 : 1
            border.color: Auth.error !== "" ? Theme.error : Qt.rgba(1, 1, 1, _field.activeFocus ? 0.4 : 0.25)

            TextInput {
                id: _field
                anchors { fill: parent; leftMargin: 20; rightMargin: 48 }
                verticalAlignment: TextInput.AlignVCenter
                color: "white"
                font.family: Theme.fontFamily
                font.pixelSize: 18
                echoMode: (Auth.prompt !== "" && Auth.promptEcho) || win.showPassword ? TextInput.Normal : TextInput.Password
                passwordCharacter: "●"
                enabled: !Auth.busy
                clip: true
                onAccepted: win._submit()
                KeyNavigation.backtab: Selection.manual ? _userField : null
                Keys.onPressed: (e) => { if (win._shortcut(e)) e.accepted = true }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    elide: Text.ElideRight
                    visible: _field.text === "" && !Auth.busy
                    text: Auth.prompt !== "" ? Auth.prompt : "Password"
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font: _field.font
                }
            }
            Text {
                anchors.centerIn: parent
                visible: Auth.busy
                text: "Signing in…"
                color: Qt.rgba(1, 1, 1, 0.75)
                font.family: Theme.fontFamily
                font.pixelSize: 16
            }
            Text {
                visible: !Auth.busy && (Auth.prompt === "" || !Auth.promptEcho)
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                text: win.showPassword ? "󰈉" : "󰈈"
                color: Qt.rgba(1, 1, 1, 0.7)
                font.family: Theme.fontFamily
                font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { win.showPassword = !win.showPassword; _field.forceActiveFocus() }
                }
            }
        }

        // Messages get a fixed space, so the prompt doesn't move when they show.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 360
            height: 70
            Column {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                width: parent.width
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: Keyboard.capsLock
                    text: "󰪛  Caps Lock is on"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 360
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: text !== ""
                    text: Auth.error !== "" ? Auth.error : Auth.message
                    color: Auth.error !== "" ? Theme.error : Qt.rgba(1, 1, 1, 0.8)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !Auth.available
                    text: "Not started by greetd: logging in is disabled"
                    color: Theme.error
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                }
            }
        }
    }

    PopupMenu {
        open: win._menu === "users"
        items: win._userItems
        x: _prompt.x + (_prompt.width - width) / 2
        y: _prompt.y + 104 + 16 + 40
        onClosed: win._menu = ""
    }

    // ── Bottom bar: session (left), status and power (right) ─────────────────
    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 32 }
        height: 44
        visible: win.showPrompt
        opacity: win.showPrompt ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 280 } }

        PillButton {
            id: _sessionButton
            anchors.left: parent.left
            visible: Sessions.sessions.length > 0
            icon: "󰍹"
            label: (Sessions.byId(Selection.session)?.name ?? "") + "  󰅃"
            tip: "Session (Ctrl+↑↓)"
            highlighted: win._menu === "sessions"
            onClicked: win._menu = win._menu === "sessions" ? "" : "sessions"
        }

        Text {
            anchors.centerIn: parent
            text: "Ctrl+←→ user  ·  Ctrl+↑↓ session  ·  Esc back"
            color: "white"
            opacity: 0.6
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }

        Row {
            anchors.right: parent.right
            spacing: 8
            PillButton {
                visible: Keyboard.available && Keyboard.layout !== ""
                icon: "󰌌"
                label: Keyboard.layout
                tip: Keyboard.multiple ? "Next keyboard layout" : "Keyboard layout"
                onClicked: { if (Keyboard.multiple) Keyboard.next(); win._focusInput() }
            }
            PillButton {
                readonly property var bat: UPower.displayDevice
                readonly property int pct: bat ? Math.round(bat.percentage * 100) : -1
                readonly property bool charging: bat && (bat.state === UPowerDeviceState.Charging
                                                         || bat.state === UPowerDeviceState.FullyCharged)
                visible: !!bat && bat.isLaptopBattery && pct >= 0
                icon: charging ? "󰂄" : ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.min(9, Math.floor(pct / 10))]
                label: pct + "%"
                tip: charging ? "Charging" : "Battery"
            }
            Repeater {
                model: Power.actions
                delegate: PillButton {
                    required property var modelData
                    icon: modelData.icon
                    tip: modelData.label
                    onClicked: win._power = modelData.id
                }
            }
        }
    }

    PopupMenu {
        open: win._menu === "sessions"
        items: win._sessionItems
        x: 32
        y: win.height - 32 - 44 - 8 - height
        onClosed: win._menu = ""
    }

    // Clicks outside an open menu close it.
    MouseArea {
        anchors.fill: parent
        z: 50
        visible: win._menu !== ""
        onClicked: { win._menu = ""; win._focusInput() }
    }

    ConfirmDialog {
        anchors.fill: parent
        open: win._power !== ""
        icon: win._powerAction?.icon ?? ""
        title: win._powerAction?.confirm ?? ""
        confirmLabel: win._powerAction?.label ?? ""
        onCanceled: { win._power = ""; win._focusInput() }
        onConfirmed: { const id = win._power; win._power = ""; Power.run(id) }
    }

    // ── Idle: any click or key shows the prompt; a printable key starts the password
    MouseArea {
        anchors.fill: parent
        enabled: !win.showPrompt
        onClicked: win.reveal()
    }
    Item {
        id: _keys
        anchors.fill: parent
        focus: !win.showPrompt
        Keys.onPressed: (e) => {
            win.reveal()
            if (!Selection.manual && e.text.length === 1 && e.text.charCodeAt(0) >= 0x20)
                _field.text += e.text
            e.accepted = true
        }
    }

    component Arrow: Text {
        id: ar
        property string tip: ""
        signal clicked()
        anchors.verticalCenter: parent.verticalCenter
        visible: Users.users.length > 0
        color: "white"
        opacity: _arMouse.containsMouse ? 1 : 0.6
        font.family: Theme.fontFamily
        font.pixelSize: 30
        MouseArea {
            id: _arMouse
            anchors.fill: parent
            anchors.margins: -10
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ar.clicked()
        }
    }
}
