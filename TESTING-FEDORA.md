# Caelestia Fedora Installation & Testing Guide

This guide covers installing and verifying Caelestia on **Fedora 44 Workstation**.

## Prerequisites

- Fedora 44 Workstation ISO (Wayland-based, already has GNOME)
- Internet connection
- At least 20 GB free disk space
- sudo/root access

---

## Step 1: Base System Setup

Boot into your Fedora 44 Workstation install. Open a terminal and run:

```sh
# First, fully update the system
sudo dnf upgrade --refresh -y

# Install fish shell (required by the installer)
sudo dnf install -y fish git

# Reboot if kernel was updated
sudo reboot
```

---

## Step 2: Clone Caelestia

```sh
# Clone to a permanent location (the installer creates symlinks from here)
git clone https://github.com/Aftab3008/caelestia.git ~/.local/share/caelestia
cd ~/.local/share/caelestia
```

> **Important:** Clone to a permanent location. The installer creates **symlinks** from your config directory, so you cannot move or delete this repo after installation.

---

## Step 3: Run the Installer

```sh
./install-fedora.fish
```

The installer will:

1. **Detect Fedora 44** and configure the correct Hyprland COPR (`ashbuk/Hyprland-Fedora`)
2. **Enable 10 COPR repositories** (quickshell, lazygit, jetbrains-mono-nerd, caskaydia-cove-nerd, material-symbols, libcava, app2unit, gpu-screen-recorder, hyprland, solopasha/hyprland)
3. **Enable RPM Fusion** (free + nonfree)
4. **Install ~60+ packages via dnf** — including `geoclue2` (location services) and `gammastep` (night light)
5. **Build and install caelestia-cli** from upstream source (Python wheel)
6. **Build and install caelestia-shell** from upstream source (CMake/Ninja)
7. **Install manual packages** — dart-sass (npm), materialyoucolor (pip), papirus-folders (git script), darkly Qt style (cmake build), Bibata-Modern-Classic cursor theme (GitHub release)
8. **Symlink all dotfiles** into `~/.config/`
9. **Install Firefox native messaging host** for live theming
10. **Run post-install hooks** — xdg-user-dirs, font cache, scheme init, shell daemon start

> **Expected time:** 15-40 minutes depending on internet speed and CPU (includes Darkly and cava source builds).

### Optional component flags

```sh
./install-fedora.fish --with-vscodium   # Install VSCodium + Caelestia VSIX
./install-fedora.fish --with-zen        # Install Zen Browser + theming
./install-fedora.fish --with-uwsm       # Install UWSM session management
./install-fedora.fish --noconfirm       # Skip all prompts
```

---

## Step 4: Post-Install Setup (Manual)

### 4.1 Install a Display Manager

Caelestia uses no display manager. Install one to get a graphical login:

```sh
# Option A: SDDM (recommended)
sudo dnf install -y sddm
sudo systemctl enable sddm --now

# Option B: GDM (already installed with Fedora Workstation)
# Just make sure it's enabled: sudo systemctl enable gdm --now
```

### 4.2 Set Fish as Default Shell

```sh
chsh -s /usr/bin/fish
```

### 4.3 Create User Configs

```sh
# Create hypr-vars.lua for your monitor layout and preferences
mkdir -p ~/.config/caelestia
cat > ~/.config/caelestia/hypr-vars.lua << 'EOF'
return {
  -- Set your monitor(s): "<name>,<resolution>@<refresh>,<position>,<scale>"
  monitors = { "eDP-1,1920x1080@60,0x0,1" },
  browser = "firefox",
  terminal = "foot",
  ide = "codium",
  -- Cursor theme (Bibata-Modern-Classic installed by installer)
  cursorTheme = "Bibata-Modern-Classic",
  cursorSize = 24,
}
EOF
```

### 4.4 Reboot

```sh
sudo reboot
```

---

## Step 5: Verification Checklist

At the GDM/SDDM login screen, click the gear icon and select **Hyprland** before logging in.

### 5.1 Hyprland Compositor

| Check            | Command / Action                 | Expected Result                      |
| ---------------- | -------------------------------- | ------------------------------------ |
| Hyprland starts  | Log in via display manager       | Desktop loads with bar and wallpaper |
| Version check    | `hyprctl version`                | Shows hyprland version               |
| Workspace switch | `Super + 1`, `Super + 2`         | Switches workspaces                  |
| Window movement  | Open terminal, `Super + Alt + 2` | Window moves to workspace 2          |
| Window tiling    | Open 2 foot terminals            | Windows tile side by side            |
| Fullscreen       | `Super + F`                      | Window toggles fullscreen            |
| Floating toggle  | `Super + V`                      | Window toggles floating mode         |

### 5.2 caelestia-shell

| Check                | Command / Action                             | Expected Result                                     |
| -------------------- | -------------------------------------------- | --------------------------------------------------- |
| Shell daemon running | `pidof quickshell`                           | Shows PID(s)                                        |
| Launcher             | `Super`                                      | Launcher opens with app list, search, actions       |
| Bar visible          | Look at top/bottom                           | Bar shows workspaces, clock, tray, status           |
| Notification daemon  | `notify-send "Test" "Hello from Caelestia"`  | Notification popup appears                          |
| Lock screen          | `Super + L` (or `Ctrl+Alt+Delete` then Lock) | Lock screen appears with blur                       |
| Dashboard            | Click clock on bar                           | Dashboard slides out with media/weather/performance |
| Sidebar              | Click tray area                              | Sidebar with quick toggles opens                    |
| Session menu         | `Ctrl+Alt+Delete`                            | Session menu (logout/shutdown/reboot) appears       |
| Media controls       | Open a media player, use `Ctrl+Super+Space`  | Play/pause works                                    |
| Clipboard history    | `Super + V`                                  | Clipboard picker opens                              |
| Emoji picker         | `Super + E`                                  | Emoji picker opens                                  |

### 5.3 caelestia-cli

| Check         | Command                                        | Expected Result                 |
| ------------- | ---------------------------------------------- | ------------------------------- |
| CLI version   | `caelestia --version`                          | Shows version number            |
| Help works    | `caelestia --help`                             | Shows all subcommands           |
| Scheme list   | `caelestia scheme list`                        | Lists all color schemes         |
| Scheme set    | `caelestia scheme set -n catppuccin`           | Colors change across shell/bar  |
| Scheme random | `caelestia scheme set --random`                | Colors change randomly          |
| Wallpaper set | `caelestia wallpaper -f /path/to/image.jpg`    | Wallpaper changes               |
| Screenshot    | `caelestia screenshot`                         | Screenshot tool opens (swappy)  |
| Shell IPC     | `caelestia shell mpris list`                   | Shows "No active player"        |
| Toggle        | `caelestia toggle sysmon`                      | Btop opens in special workspace |
| Shell restart | `caelestia shell -k` then `caelestia shell -d` | Shell restarts cleanly          |

### 5.4 Terminal & Shell

| Check           | Command / Action            | Expected Result                 |
| --------------- | --------------------------- | ------------------------------- |
| Foot terminal   | `Super + T`                 | Foot terminal opens             |
| Fish shell      | `echo $SHELL`               | `/usr/bin/fish`                 |
| Starship prompt | Look at prompt              | Styled prompt with git/dir info |
| eza alias       | `ls` (in fish)              | Colored eza output with icons   |
| zoxide          | `z ~/.config`               | Jumps to config dir             |
| direnv          | Create `.envrc` in temp dir | Auto-loads on cd                |

### 5.5 Audio (PipeWire)

| Check            | Command / Action                     | Expected Result           |
| ---------------- | ------------------------------------ | ------------------------- |
| PipeWire running | `pactl info \| grep "Server Name"`   | Shows "PipeWire"          |
| Audio devices    | `wpctl status`                       | Lists audio sinks/sources |
| Volume control   | `Super + F1` (volume keys)           | Volume OSD appears        |
| pavucontrol      | Launch `pavucontrol` from launcher   | GUI audio mixer opens     |
| Test audio       | Play audio from browser/media player | Sound plays               |

### 5.6 Bluetooth

| Check             | Command / Action             | Expected Result                 |
| ----------------- | ---------------------------- | ------------------------------- |
| Bluez running     | `systemctl status bluetooth` | Active/running                  |
| Bluetooth devices | `bluetoothctl devices`       | Lists (or empty if none paired) |

### 5.7 Network

| Check          | Command / Action       | Expected Result       |
| -------------- | ---------------------- | --------------------- |
| NetworkManager | `nmcli general status` | Shows connected state |
| nmcli applet   | Check bar tray         | Network icon visible  |

### 5.8 Firefox Theming

| Check                  | Command / Action                                               | Expected Result                       |
| ---------------------- | -------------------------------------------------------------- | ------------------------------------- |
| userChrome.css active  | Open Firefox                                                   | Rounded corners, centered URL bar     |
| CaelestiaFox extension | Check `about:addons`                                           | Extension is installed                |
| Live color sync        | `caelestia scheme set --random`                                | Firefox UI colors update in real-time |
| Native host installed  | `ls /usr/lib/mozilla/native-messaging-hosts/caelestiafox.json` | File exists                           |
| Native host app        | `ls /usr/lib/caelestia/caelestiafox`                           | File exists and executable            |

### 5.9 GTK/Qt Theming

| Check             | Command / Action                                       | Expected Result                  |
| ----------------- | ------------------------------------------------------ | -------------------------------- |
| GTK theme         | `gsettings get org.gnome.desktop.interface gtk-theme`  | Shows `adw-gtk3-dark` or similar |
| Papirus icons     | `gsettings get org.gnome.desktop.interface icon-theme` | Shows `Papirus-Dark`             |
| Qt platform theme | `echo $QT_QPA_PLATFORMTHEME`                           | Shows `qt5ct`                    |
| Qt5 config        | `qt5ct` (launch from terminal)                         | Opens Qt5 settings               |
| Qt6 config        | `qt6ct` (launch from terminal)                         | Opens Qt6 settings               |
| Darkly (if built) | Check qt5ct/qt6ct style dropdown                       | Darkly appears as option         |
| Cursor theme      | `echo $XCURSOR_THEME`                                  | Shows `Bibata-Modern-Classic`    |
| Cursor visible    | Move mouse on desktop                                  | Bibata cursor renders correctly  |

### 5.10 System Monitoring

| Check              | Command / Action          | Expected Result                        |
| ------------------ | ------------------------- | -------------------------------------- |
| Fastfetch          | `fastfetch`               | Shows system info with Fedora logo     |
| Btop               | `btop`                    | System monitor TUI opens               |
| Btop in special ws | `caelestia toggle sysmon` | Btop opens in special:sysmon workspace |

### 5.11 File Manager

| Check                 | Command / Action            | Expected Result                |
| --------------------- | --------------------------- | ------------------------------ |
| Thunar                | Launch Thunar from launcher | File manager opens             |
| Thunar custom actions | Right-click any file        | Shows Caelestia custom actions |

### 5.12 Fonts

| Check               | Command                                 | Expected Result  |
| ------------------- | --------------------------------------- | ---------------- |
| JetBrains Mono Nerd | `fc-list \| grep -i "jetbrains.*nerd"`  | Font file listed |
| Caskaydia Cove Nerd | `fc-list \| grep -i "caskaydia.*nerd"`  | Font file listed |
| Material Symbols    | `fc-list \| grep -i "material.*symbol"` | Font file listed |
| Noto CJK            | `fc-list \| grep -i "noto.*cjk"`        | Font file listed |
| Noto Emoji          | `fc-list \| grep -i "noto.*emoji"`      | Font file listed |

---

## Step 6: Troubleshooting Common Issues

### Hyprland doesn't start (black screen / back to login)

```sh
# Check the log
cat /tmp/hypr/$(ls /tmp/hypr/ | tail -1)/hyprland.log

# Common fixes:
# 1. Wrong monitor config in hypr-vars.lua — check with:
hyprctl monitors

# 2. Missing GPU drivers — install:
sudo dnf install -y mesa-dri-drivers

# 3. Verify hyprland installed from correct COPR:
rpm -qi hyprland | grep Vendor
```

### Shell doesn't appear (no bar/launcher)

```sh
# Check quickshell installed:
rpm -q quickshell
# or:
rpm -q quickshell-git

# Check shell daemon:
caelestia shell -d

# View shell logs:
caelestia shell --log

# If quickshell symbol errors:
# You may have a Qt version mismatch. Rebuild from source:
sudo dnf install -y qt6-qtdeclarative-devel qt6-qtbase-devel
```

### caelestia command not found

```sh
# Check Python path:
python3 -c "import caelestia; print(caelestia.__file__)"

# If missing, reinstall:
cd /tmp && git clone --depth=1 https://github.com/caelestia-dots/cli.git
cd cli && python3 -m build --wheel
sudo python3 -m pip install --break-system-packages dist/*.whl
```

### Font not rendering correctly

```sh
# Refresh font cache:
fc-cache -fv

# Check font installed:
fc-list | grep -i <font-name>

# If missing Nerd Font from COPR:
sudo dnf copr enable aquacash5/nerd-fonts -y
sudo dnf install caskaydia-cove-nerd-fonts -y
```

### package not found during install

```sh
# Some packages move between Fedora releases. Search manually:
dnf search <package-name>

# Or check if COPR is enabled:
dnf copr list

# Re-enable specific COPR:
sudo dnf copr enable <owner>/<repo> -y
```

### COPR repo not available for Fedora 44

```sh
# Some COPRs lag behind. Check build status:
curl -s "https://copr.fedorainfracloud.org/coprs/<owner>/<repo>/builds/" | grep "fedora-44"

# If no F44 build, try the rawhide build or install from source.
# For critical packages (quickshell, hyprland), use alternate COPRs:
# - quickshell: errornointernet/quickshell has F44 builds
# - hyprland: ashbuk/Hyprland-Fedora supports F44
```

---

## Step 7: Verification Script

Run this script after installation to auto-check everything:

```sh
#!/usr/bin/env fish
# verify-caelestia.fish — automated verification

set -l failed 0
set -l passed 0

function check -a name cmd
    if eval $cmd >/dev/null 2>&1
        set_color green
        echo "  ✓ $name"
        set_color normal
        set passed (math $passed + 1)
    else
        set_color red
        echo "  ✗ $name"
        set_color normal
        set failed (math $failed + 1)
    end
end

echo "Caelestia Fedora Verification"
echo "============================="
echo

echo "Hyprland:"
check "hyprland installed" "rpm -q hyprland"
check "hyprland running" "pgrep Hyprland"
check "xdg-desktop-portal-hyprland" "rpm -q xdg-desktop-portal-hyprland"

echo
echo "Shell:"
check "quickshell installed" "rpm -q quickshell 2>/dev/null || rpm -q quickshell-git 2>/dev/null"
check "shell daemon running" "pgrep -f 'qs.*caelestia'"
check "caelestia command" "command -v caelestia"

echo
echo "Services:"
check "pipewire running" "pgrep pipewire"
check "wireplumber running" "pgrep wireplumber"
check "bluetooth running" "systemctl is-active bluetooth"
check "NetworkManager running" "systemctl is-active NetworkManager"
check "gnome-keyring running" "pgrep gnome-keyring"

echo
echo "Tools:"
check "foot terminal" "rpm -q foot"
check "fish shell" "rpm -q fish"
check "fastfetch" "rpm -q fastfetch"
check "btop" "rpm -q btop"
check "starship" "command -v starship"
check "thunar" "rpm -q thunar"
check "eza" "rpm -q eza"
check "zoxide" "rpm -q zoxide"
check "direnv" "rpm -q direnv"
check "bat" "rpm -q bat"
check "ripgrep" "rpm -q ripgrep"
check "jq" "rpm -q jq"
check "trash-cli" "rpm -q trash-cli"
check "fuzzel" "rpm -q fuzzel"
check "wl-clipboard" "rpm -q wl-clipboard"
check "cliphist" "rpm -q cliphist"
check "slurp" "rpm -q slurp"
check "grim" "rpm -q grim"
check "swappy" "rpm -q swappy"
check "hyprpicker" "rpm -q hyprpicker"
check "ydotool" "rpm -q ydotool"
check "gpu-screen-recorder" "rpm -q gpu-screen-recorder"
check "brightnessctl" "rpm -q brightnessctl"
check "ddcutil" "rpm -q ddcutil"
check "app2unit" "rpm -q app2unit"

echo
echo "Themes/Fonts:"
check "adw-gtk3-theme" "rpm -q adw-gtk3-theme"
check "papirus-icon-theme" "rpm -q papirus-icon-theme"
check "noto sans fonts" "rpm -q google-noto-sans-fonts"
check "noto sans cjk" "rpm -q google-noto-sans-cjk-fonts"
check "noto emoji" "rpm -q google-noto-emoji-fonts"
check "jetbrains mono nerd" 'fc-list | grep -qi "jetbrains.*nerd"'
check "caskaydia cove nerd" 'fc-list | grep -qi "caskaydia.*nerd"'
check "material symbols" 'fc-list | grep -qi "material.*symbol"'

echo
echo "Config files:"
check "hypr config" "test -L ~/.config/hypr"
check "fish config" "test -L ~/.config/fish"
check "foot config" "test -L ~/.config/foot"
check "fastfetch config" "test -L ~/.config/fastfetch"
check "btop config" "test -L ~/.config/btop"
check "starship config" "test -L ~/.config/starship.toml"
check "thunar config" "test -L ~/.config/Thunar"

echo
echo "Firefox:"
check "firefox installed" "rpm -q firefox"
check "native host manifest" "test -f /usr/lib/mozilla/native-messaging-hosts/caelestiafox.json"
check "native host app" "test -x /usr/lib/caelestia/caelestiafox"

echo
echo "─────────────────────────────────"
echo "Passed: $passed  Failed: $failed"
echo "─────────────────────────────────"

if test $failed -eq 0
    set_color green
    echo "All checks passed! Caelestia is working."
    set_color normal
else
    set_color red
    echo "$failed check(s) failed. Review the items above."
    set_color normal
    exit 1
end
```

Save as `verify-caelestia.fish`, make executable, and run:

```sh
chmod +x verify-caelestia.fish
./verify-caelestia.fish
```

---

## Fedora 44-Specific Notes

| Area                             | Detail                                                                                                                                                                     |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Hyprland**                     | No official Fedora 44 package. Uses `ashbuk/Hyprland-Fedora` COPR (v0.55.1+). The installer auto-selects this for F44+.                                                    |
| **quickshell**                   | Available from `errornointernet/quickshell` COPR. Has successful F44 builds.                                                                                               |
| **libcava**                      | From `zawertun/scrapyard` COPR. If no F44 build exists, the installer automatically builds `cava` from source with `-DBUILD_SHARED_LIBS=ON`.                               |
| **uwsm + cliphist**              | From `solopasha/hyprland` COPR — always enabled alongside `ashbuk/Hyprland-Fedora` on F44+ (each COPR provides different packages).                                        |
| **papirus-folders**              | No Fedora package. Installer builds from GitHub.                                                                                                                           |
| **darkly Qt style**              | Built from source by installer. Deps: `cmake`, `extra-cmake-modules`, `kf6-kdecoration-devel`, `kf6-kirigami-devel`, `kf6-kcoreaddons-devel`. All installed automatically. |
| **Bibata-Modern-Classic cursor** | Not in Fedora repos. Installer downloads latest release tarball from GitHub (`ful1e5/Bibata_Cursor`). Matches Caelestia's Material You aesthetic.                          |
| **Qt theming**                   | `QT_QPA_PLATFORMTHEME=qt5ct` (not `qtengine` which is Arch-only). Configured in both `hypr/hyprland/env.lua` and `uwsm/env`.                                               |
| **spicetify**                    | Manual install via upstream shell script. Not in dnf/flatpak.                                                                                                              |
| **geoclue2 + gammastep**         | Both installed automatically. `gammastep` provides night-light (color temperature shift). Requires location permission the first time.                                     |
