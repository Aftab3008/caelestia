local vars = require("variables")
local fn   = require("hyprland.functions")

hl.on("hyprland.start", function()
    -- CRITICAL: Export Wayland env vars into D-Bus and systemd user session.
    -- Without this, apps launched via keybinds (Super+T, Super+W, etc.) silently
    -- fail because they cannot connect to the Wayland compositor.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland DISPLAY")

    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/bin/lxpolkit")  -- polkit-gnome dropped in Fedora 44; lxpolkit is the replacement

    -- Ensure XDG desktop portals are running with the Hyprland portal active.
    -- The sleep gives Hyprland a moment to register before portals try to connect.
    hl.exec_cmd("sleep 1 && systemctl --user restart xdg-desktop-portal-hyprland")
    hl.exec_cmd("sleep 2 && systemctl --user restart xdg-desktop-portal")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Location provider and night light
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    hl.exec_cmd("sleep 1 && gammastep")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- Start shell
    hl.exec_cmd("caelestia shell -d")
end)

-- Resizer listener
hl.on("window.title", function(win)
    local d = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }
    local pip = fn.move_actions(win) or {}

    fn.resizer(win, "Bitwarden", 20, 54, d, true)
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip, false)
end)

hl.on("window.open", function(win)
    local d = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }
    local pip = fn.move_actions(win) or {}

    fn.resizer(win, "Bitwarden", 20, 54, d, true)
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip, false)
end)
