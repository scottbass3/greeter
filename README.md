# scottbass3-greeter

A [greetd](https://sr.ht/~kennylevinsen/greetd/) greeter for Hyprland, built on
[Quickshell](https://quickshell.org), with the look of the
[scottbass3-shell](https://github.com/scottbass3/shell) lock screen: the
wallpaper with the clock, then a blurred login prompt on a click or a key.

- Users from `/etc/passwd` (regular UIDs, real shells), with their avatar, or
  a name typed by hand ("Other user")
- Password and multi-step PAM logins (one-time codes, fingerprint messages)
- Sessions from `/usr/share/wayland-sessions` (and `/usr/share/xsessions`
  through `startx`)
- The last user and each user's last session are remembered
- Suspend, restart and power off, after a confirmation
- Caps Lock warning, keyboard layout switch, battery level, show password
- Every screen shows the wallpaper; the prompt follows the focused one

## Install

### NixOS

The flake's module sets greetd up:

```nix
{
  inputs.scottbass3-greeter.url = "github:scottbass3/greeter";

  # in the system's modules:
  imports = [ inputs.scottbass3-greeter.nixosModules.default ];
  services.scottbass3-greeter = {
    enable = true;
    settings.wallpaper = "/etc/scottbass3-greeter/wallpaper.png";  # config.json keys, see below
    extraHyprlandConfig = ''hl.monitor({ output = "", mode = "preferred" })'';  # optional
  };
}
```

It also follows `services.xserver.xkb` for the keyboard, lists the system's
sessions and installs the JetBrains Mono Nerd Font.

### Arch Linux

AUR: `scottbass3-greeter-git`. Then point greetd at it in
`/etc/greetd/config.toml`:

```toml
[default_session]
command = "start-hyprland -- -c /usr/share/scottbass3-greeter/hypr/greeter.lua"
user = "greeter"
```

The change applies at the next greetd start (`sudo systemctl restart greetd`
ends the current session). If the greeter doesn't come up, switch to another
console with Ctrl+Alt+F2, log in there and restore your previous `command`.

## Keys

| Keys | Action |
| --- | --- |
| any key, click | show the prompt (a typed character starts the password) |
| Ctrl+← / Ctrl+→ | previous / next user, then "Other user" |
| Ctrl+↑ / Ctrl+↓ | previous / next session |
| Enter | log in, or confirm a dialog |
| Esc | close a menu or dialog, cancel a PAM question, hide the prompt |

## Configuration

`/etc/scottbass3-greeter/config.json`; every key is optional (see
[`config.example.json`](config.example.json)):

| Key | Default | |
| --- | --- | --- |
| `wallpaper` | none (a gradient) | image readable by the `greeter` user |
| `font` | `JetBrainsMono Nerd Font` | needs Nerd Font icons |
| `locale` | `LANG` from `/etc/locale.conf` | for the date, e.g. `fr_FR` |
| `clock24h` | `true` | |
| `hiddenUsers` | `[]` | user names not to list |
| `defaultSession` | the first one | e.g. `wayland/hyprland` (file name of the `.desktop`) |
| `sessionDirs` | `/usr/share/wayland-sessions`, `/usr/share/xsessions` | where to find sessions; X11 ones have `xsessions` in their path |
| `userThemes` | `true` | use the wallpaper and colors synced by each user's shell |
| `userThemesDir` | `/var/lib/scottbass3-greeter/users` | |
| `colors` | the shell's dark theme | Material 3 roles: `primary`, `onPrimary`, `surface`, `secondaryContainer`, `error`… |

The keyboard layout comes from the system settings (`localectl
set-x11-keymap`, else the console keymap). `/etc/scottbass3-greeter/hyprland.lua`,
if present, is loaded after the greeter's Hyprland config to adjust monitors,
input or anything else.

Avatars are read from `/var/lib/AccountsService/icons/<user>`; users without
one get their initials.

### Users' own themes

scottbass3-shell can copy a user's wallpaper, colors and avatar to
`/var/lib/scottbass3-greeter/users/<user>/` (Settings → Appearance → Login
screen), and the greeter shows them while that user is selected. The
directory is shared like `/tmp`; the greeter only uses an entry owned by the
user it is named after. Other shells can do the same with a `theme.json`:

```json
{ "wallpaper": "wallpaper.jpg", "avatar": "face", "colors": { "primary": "#D0BCFF" } }
```

## Development

Run it from a checkout without greetd, with greetd's `fakegreet` (user `user`,
password `password`, then answer `9`):

```sh
cargo install --git https://git.sr.ht/~kennylevinsen/greetd fakegreet
fakegreet "quickshell -p $PWD"
```

`SCOTTBASS3_GREETER_CONFIG` points it at another configuration file.

## License

[GPL-3.0-or-later](LICENSE).
