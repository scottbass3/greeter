-- Hyprland session for scottbass3-greeter, started by greetd:
--     command = "start-hyprland -- -c /usr/share/scottbass3-greeter/hypr/greeter.lua"
-- It runs the greeter and ends once the greeter quits, which it does after
-- starting the user's session. /etc/scottbass3-greeter/hyprland.lua, when
-- present, is loaded last to adjust anything (monitors, input…).

local root = debug.getinfo(1, "S").source:match("^@(.*)/hypr/[^/]+$") or "/usr/share/scottbass3-greeter"
local function shq(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

-- The system keyboard layout: localectl's X11 settings, else the console keymap.
local function read(path)
    local f = io.open(path)
    if not f then return nil end
    local text = f:read("a")
    f:close()
    return text
end

local kb = { layout = "us", variant = "", options = "" }
local x11 = read("/etc/X11/xorg.conf.d/00-keyboard.conf")
if x11 and x11:match('"XkbLayout"%s+"([^"]+)"') then
    kb.layout  = x11:match('"XkbLayout"%s+"([^"]+)"')
    kb.variant = x11:match('"XkbVariant"%s+"([^"]*)"') or ""
    kb.options = x11:match('"XkbOptions"%s+"([^"]*)"') or ""
else
    local keymap = (read("/etc/vconsole.conf") or ""):match("KEYMAP=[\"']?([%w_]+)")
    if keymap then kb.layout = keymap end
end

hl.config({
    animations = { enabled = false },
    decoration = { rounding = 0, blur = { enabled = false } },
    general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = "rgb(000000)",
        -- greetd doesn't pass the watchdog fd through start-hyprland
        disable_watchdog_warning = true,
    },
    ecosystem = { no_update_news = true, no_donation_nag = true },
    input = {
        kb_layout  = kb.layout,
        kb_variant = kb.variant,
        kb_options = kb.options,
        numlock_by_default = true,
        touchpad = { tap_to_click = true },
    },
})

-- No keybindings on purpose: the greeter must not give the user any control.

hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -p " .. shq(root) .. "; hyprctl dispatch 'hl.dsp.exit()'")
end)

local local_config = "/etc/scottbass3-greeter/hyprland.lua"
if io.open(local_config) then loadfile(local_config)() end
