pragma Singleton
import QtQuick
import Quickshell.Io

// Desktop sessions from /usr/share/wayland-sessions and /usr/share/xsessions.
// X11 sessions are offered only when startx (xorg-xinit) can start them.
QtObject {
    id: root

    // [{ id, name, exec: [argv], x11, desktopNames }]
    property var sessions: []
    property bool loaded: false

    function byId(id) { return sessions.find(s => s.id === id) ?? null }

    // Argv and environment greetd should start the session with.
    function command(s) {
        return s.x11 ? ["startx", "/usr/bin/env"].concat(s.exec) : s.exec
    }
    function environment(s) {
        const env = ["XDG_SESSION_TYPE=" + (s.x11 ? "x11" : "wayland")]
        if (s.desktopNames !== "") {
            env.push("XDG_CURRENT_DESKTOP=" + s.desktopNames)
            env.push("XDG_SESSION_DESKTOP=" + s.desktopNames.split(":")[0])
        }
        return env
    }

    // Exec value to argv: quotes respected, field codes (%f, %U…) dropped.
    function _argv(exec) {
        const out = []
        let cur = "", quote = false, has = false
        for (let i = 0; i < exec.length; i++) {
            const c = exec[i]
            if (c === "\"") { quote = !quote; has = true }
            else if (c === "\\" && quote && i + 1 < exec.length) { cur += exec[++i]; has = true }
            else if (/\s/.test(c) && !quote) { if (has) out.push(cur); cur = ""; has = false }
            else { cur += c; has = true }
        }
        if (has) out.push(cur)
        return out.filter(a => !/^%[a-zA-Z]$/.test(a)).map(a => a.replace(/%%/g, "%"))
    }

    function _parse(text) {
        const list = []
        for (const block of text.split("\n@@file ").slice(1)) {
            const lines = block.split("\n")
            const header = lines[0].split(" ")   // path x11 tryexec-ok startx-ok
            const path = header[0], x11 = header[1] === "1"
            if (header[2] !== "1" || (x11 && header[3] !== "1")) continue
            const kv = {}
            let inEntry = false
            for (const l of lines.slice(1)) {
                const t = l.trim()
                if (t.startsWith("[")) { inEntry = t === "[Desktop Entry]"; continue }
                const eq = t.indexOf("=")
                if (!inEntry || eq < 0) continue
                const k = t.slice(0, eq).trim()
                if (kv[k] === undefined) kv[k] = t.slice(eq + 1).trim()
            }
            if (!kv.Exec || kv.Hidden === "true" || kv.NoDisplay === "true") continue
            const file = path.split("/").pop().replace(/\.desktop$/, "")
            list.push({
                id: (x11 ? "x11/" : "wayland/") + file,
                name: (kv.Name || file) + (x11 ? " (X11)" : ""),
                exec: _argv(kv.Exec),
                x11: x11,
                desktopNames: (kv.DesktopNames || "").replace(/;+$/, "").replace(/;/g, ":")
            })
        }
        list.sort((a, b) => a.name.localeCompare(b.name))
        sessions = list
        loaded = true
    }

    property Process _scan: Process {
        running: true
        command: ["sh", "-c", `
            startx=0; command -v startx >/dev/null 2>&1 && startx=1
            for dir in /usr/share/wayland-sessions /usr/share/xsessions; do
                x11=0; [ "$dir" = /usr/share/xsessions ] && x11=1
                for f in "$dir"/*.desktop; do
                    [ -f "$f" ] || continue
                    try=$(sed -n 's/^TryExec=//p' "$f" | head -n1)
                    ok=1; [ -n "$try" ] && ! command -v "$try" >/dev/null 2>&1 && ok=0
                    printf '\\n@@file %s %s %s %s\\n' "$f" "$x11" "$ok" "$startx"
                    cat "$f"
                done
            done`]
        stdout: StdioCollector { onStreamFinished: root._parse(text) }
    }
}
