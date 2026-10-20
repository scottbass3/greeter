pragma Singleton
import QtQuick
import Quickshell.Services.Greetd
import "."

// Login through greetd. The password typed in the field answers PAM's first
// secret question; any further question (a one-time code…) is shown as
// `prompt` and answered with answer().
QtObject {
    id: root

    readonly property bool available: Greetd.available
    property bool   busy: false
    property string prompt: ""        // follow-up question, "" when none
    property bool   promptEcho: false
    property string message: ""       // PAM information (e.g. fingerprint reader)
    property string error: ""

    signal failed()

    property string _password: ""
    property bool   _passwordSent: false

    function login(password) {
        if (busy) return
        error = ""
        message = ""
        if (Selection.loginName === "") { error = "Enter a user name"; return }
        if (!Sessions.byId(Selection.session)) { error = "No session to start"; return }
        _password = password
        _passwordSent = false
        busy = true
        Greetd.createSession(Selection.loginName)
    }

    function answer(text) {
        if (prompt === "") return
        prompt = ""
        busy = true
        Greetd.respond(text)
    }

    function cancel() {
        if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession()
        _reset()
    }

    function _reset() {
        busy = false
        prompt = ""
        _password = ""
        _passwordSent = false
    }

    function _describe(msg) {
        if (msg === "" || /AUTH_ERR|authentication failure/i.test(msg)) return "Wrong password"
        if (/MAXTRIES/i.test(msg)) return "Too many attempts"
        if (/USER_UNKNOWN/i.test(msg)) return "Unknown user"
        return msg
    }

    property Connections _greetd: Connections {
        target: Greetd

        function onAuthMessage(msg, isError, responseRequired, echo) {
            if (!responseRequired) {
                if (isError) root.error = msg; else root.message = msg
                return
            }
            if (!echo && !root._passwordSent) {
                root._passwordSent = true
                Greetd.respond(root._password)
                root._password = ""
                return
            }
            root.busy = false
            root.prompt = msg
            root.promptEcho = echo
        }
        function onAuthFailure(msg) {
            root._reset()
            root.error = root._describe(msg)
            root.failed()
        }
        function onError(msg) {
            root._reset()
            root.error = msg
            root.failed()
        }
        function onReadyToLaunch() {
            const s = Sessions.byId(Selection.session)
            LastLogin.remember(Selection.loginName, s.id)
            Greetd.launch(Sessions.command(s), Sessions.environment(s), true)
        }
    }
}
