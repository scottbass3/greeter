pragma Singleton
import QtQuick
import "."

// The user and session the next login is for. `user` is "" while a name is
// typed by hand ("Other user").
QtObject {
    id: root

    property string user: ""
    property string typedUser: ""
    property bool   manual: false
    property string session: ""

    readonly property string loginName: manual ? typedUser.trim() : user
    readonly property var    userInfo: Users.byName(user)

    function _pickSession() {
        const remembered = LastLogin.sessionFor(loginName)
        const wanted = [remembered, Config.defaultSession].filter(s => s !== "")
        for (const id of wanted)
            if (Sessions.byId(id)) { session = id; return }
        if (!Sessions.byId(session)) session = Sessions.sessions.length ? Sessions.sessions[0].id : ""
    }

    function selectUser(name) {
        manual = false
        user = name
        _pickSession()
    }
    function selectManual() {
        manual = true
        typedUser = ""
    }
    function cycleUser(d) {
        const list = Users.users
        if (list.length === 0) { selectManual(); return }
        // The "Other user" entry sits after the last user.
        const at = manual ? list.length : Math.max(0, list.findIndex(u => u.name === user))
        const next = (at + d + list.length + 1) % (list.length + 1)
        if (next === list.length) selectManual(); else selectUser(list[next].name)
    }
    function cycleSession(d) {
        const list = Sessions.sessions
        if (list.length === 0) return
        const at = Math.max(0, list.findIndex(s => s.id === session))
        session = list[(at + d + list.length) % list.length].id
    }

    // The last user, else the first; typing a name when there is none to list.
    function _init() {
        if (!Users.loaded || !LastLogin.loaded) return
        if (user === "" && !manual) {
            const lastName = LastLogin.lastUser
            const last = Users.byName(lastName)
            // A name typed by hand last time comes back typed, unless it is hidden.
            const typed = lastName !== "" && !last && Config.hiddenUsers.indexOf(lastName) < 0
            if (last) { selectUser(last.name); return }
            if (typed || Users.users.length === 0) {
                manual = true
                typedUser = typed ? lastName : ""
            } else {
                selectUser(Users.users[0].name)
                return
            }
        }
        _pickSession()
    }

    readonly property var _watch: [Users.loaded, LastLogin.loaded, Users.users, Sessions.sessions, LastLogin.lastUser]
    on_WatchChanged: _init()
    onTypedUserChanged: _pickSession()
}
