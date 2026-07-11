#!/usr/bin/env fish
#
# install-fedora.fish — Caelestia dotfiles installer for Fedora
#
# Usage:
#   ./install-fedora.fish [--noconfirm] [--core-only]
#                         [--with-spotify] [--with-vscodium] [--with-vscode]
#                         [--with-zed] [--with-zen] [--with-uwsm]
#
# This script:
#   1. Detects Fedora and refuses to run on other distros
#   2. Enables all required COPR repositories
#   3. Enables RPM Fusion
#   4. Installs all dnf packages from manifest-fedora.toml
#   5. Builds and installs caelestia-cli from upstream source
#   6. Builds and installs caelestia-shell from upstream source
#   7. Handles manual packages (npm, pip, GitHub, darkly build)
#   8. Symlinks all dotfiles into place
#   9. Runs post-install hooks

argparse -n 'install-fedora.fish' -X 0 \
    'h/help' \
    'noconfirm' \
    'core-only' \
    'with-spotify' \
    'with-vscodium' \
    'with-vscode' \
    'with-zed' \
    'with-zen' \
    'with-uwsm' \
    -- $argv
or exit 1

if set -q _flag_h
    echo 'usage: ./install-fedora.fish [-h] [--noconfirm] [--core-only]'
    echo '                            [--with-spotify] [--with-vscodium] [--with-vscode]'
    echo '                            [--with-zed] [--with-zen] [--with-uwsm]'
    echo
    echo 'options:'
    echo '  -h, --help        show this help message and exit'
    echo '  --noconfirm        skip confirmations (dnf -y)'
    echo '  --core-only        install only the default (core) components'
    echo '  --with-spotify     install Spotify + Spicetify theming'
    echo '  --with-vscodium    install VSCodium + Caelestia extension'
    echo '  --with-vscode      install VSCode + Caelestia extension'
    echo '  --with-zed         install Zed editor configs'
    echo '  --with-zen         install Zen Browser theming'
    echo '  --with-uwsm        install UWSM session management'
    exit 0
end


# ── Helpers ────────────────────────────────────────────────────────────────

function _log -a colour text
    set_color $colour
    echo ":: $text"
    set_color normal
end

function log -a text
    _log cyan $text
end

function success -a text
    _log green $text
end

function warn -a text
    _log yellow $text
end

function error -a text
    _log red $text
end

function confirm_overwrite -a path
    if test -e "$path" -o -L "$path"
        if set -q _flag_noconfirm
            set_color blue
            echo ":: $path already exists. Removing (--noconfirm)..."
            set_color normal
            rm -rf "$path"
        else
            set_color blue
            read -l -P ":: $path already exists. Overwrite? [y/N] " confirm
            set_color normal
            if test "$confirm" != 'y' -a "$confirm" != 'Y'
                log "Skipping $path..."
                return 1
            end
            rm -rf "$path"
        end
    else
        # Also remove if parent is a symlink we'd break
        set -l parent (dirname "$path")
        if test -L "$parent"
            rm -rf "$path" 2>/dev/null
        end
    end
    return 0
end

function run_hook -a hook_name
    set -l cmds $$hook_name
    if test (count $cmds) -eq 0
        return 0
    end
    log "Running $hook_name hooks..."
    for cmd in $cmds
        set -l expanded (eval echo "$cmd")
        eval "$expanded" 2>/dev/null
        or warn "Hook failed (non-fatal): $cmd"
    end
end


# ── Distro check ────────────────────────────────────────────────────────────

if test ! -f /etc/os-release
    error "Cannot detect distribution. /etc/os-release not found."
    exit 1
end

# /etc/os-release uses bash syntax (KEY="value"), so fish's 'source' fails.
# Use awk to extract values instead.
set -l distro_id (awk -F= '/^ID=/ {gsub(/"/,"",$2); print $2}' /etc/os-release)
if test "$distro_id" != "fedora"
    error "This installer is for Fedora only. Detected: $distro_id"
    exit 1
end

set -l fedora_version (awk -F= '/^VERSION_ID=/ {gsub(/"/,"",$2); print $2}' /etc/os-release)

success "Detected Fedora $fedora_version"

# Fedora 43+ dropped Hyprland from official repos.
# Fedora 44: solopasha/hyprland is behind (0.51). Use ashbuk/Hyprland-Fedora.
set -l hyprland_copr "solopasha/hyprland"
if test "$fedora_version" -ge 44
    set hyprland_copr "ashbuk/Hyprland-Fedora"
    warn "Fedora $fedora_version: using $hyprland_copr COPR for Hyprland (official repo dropped it, solopasha outdated)"
else if test "$fedora_version" -ge 43
    warn "Fedora $fedora_version: Hyprland not in official repos. Using $hyprland_copr COPR."
end


# ── Variables ────────────────────────────────────────────────────────────────

set -q _flag_noconfirm; and set dnf_opts -y; or set dnf_opts ""
set -l config_home $XDG_CONFIG_HOME
test -z "$config_home"; and set config_home "$HOME/.config"
set -l state_home $XDG_STATE_HOME
test -z "$state_home"; and set state_home "$HOME/.local/state"
set -l data_home $XDG_DATA_HOME
test -z "$data_home"; and set data_home "$HOME/.local/share"

# Repo root (where this script lives)
set -l dots_dir (dirname (realpath (status filename)))
set -x CAELESTIA_DOTS "$dots_dir"


# ── Banner ───────────────────────────────────────────────────────────────────

set_color magenta
echo '╭─────────────────────────────────────────────────╮'
echo '│      ______           __          __  _         │'
echo '│     / ____/___ ____  / /__  _____/ /_(_)___ _   │'
echo '│    / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/   │'
echo '│   / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /    │'
echo '│   \____/\__,_/\___/_/\___/____/\__/_/\__,_/     │'
echo '│                                                 │'
echo '│              Fedora Edition                      │'
echo '╰─────────────────────────────────────────────────╯'
set_color normal

log 'Welcome to the Caelestia dotfiles installer for Fedora!'
log 'This will install and configure a complete Hyprland desktop.'


# ── COPR Repositories ────────────────────────────────────────────────────────

function enable_coprs
    log 'Enabling COPR repositories...'

    set -l coprs \
        "$hyprland_copr" \
        "solopasha/hyprland" \
        "errornointernet/quickshell" \
        "atim/lazygit" \
        "maveonair/jetbrains-mono-nerd-fonts" \
        "aquacash5/nerd-fonts" \
        "purian23/material-symbols-fonts" \
        "zawertun/scrapyard" \
        "celestelove/app2unit" \
        "brycensranch/gpu-screen-recorder-git"

    for copr in $coprs
        log "  Enabling $copr..."
        sudo dnf copr enable $dnf_opts "$copr"
        or warn "  Failed to enable $copr (continuing anyway)"
    end
end


# ── RPM Fusion ───────────────────────────────────────────────────────────────

function enable_rpmfusion
    if rpm -q rpmfusion-free-release >/dev/null 2>&1
        log 'RPM Fusion already enabled.'
        return 0
    end
    log 'Enabling RPM Fusion (free and nonfree)...'
    sudo dnf install $dnf_opts \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$fedora_version.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$fedora_version.noarch.rpm"
    or warn 'Failed to enable RPM Fusion (continuing)'
end


# ── System Update ────────────────────────────────────────────────────────────

function system_update
    log 'Updating system packages...'
    sudo dnf upgrade $dnf_opts --refresh
end


# ── Package Installation ─────────────────────────────────────────────────────

function install_core_packages
    log 'Installing core system and desktop packages...'

    # Base system packages
    sudo dnf install $dnf_opts \
        fish git curl jq \
        NetworkManager bluez bluez-utils \
        pipewire pipewire-pulseaudio pipewire-alsa \
        pipewire-jack-audio-connection-kit wireplumber pavucontrol \
        gnome-keyring polkit-gnome \
        wl-clipboard ydotool trash-cli \
        inotify-tools xdg-user-dirs \
        google-noto-sans-fonts google-noto-sans-cjk-fonts google-noto-emoji-fonts \
        eza zoxide direnv \
        bat ripgrep \
        thunar foot fastfetch btop micro starship firefox \
        adw-gtk3-theme papirus-icon-theme \
        qt5ct qt6ct qt5-qtstyleplugins kf6-frameworkintegration \
        libnotify grim slurp swappy fuzzel \
        ddcutil brightnessctl lm_sensors aubio libqalculate \
        geoclue2 gammastep \
        cmake ninja-build gcc-c++ \
        python3-build python3-installer python3-hatch-vcs python3-pip \
        pkgconf-pkg-config pipewire-devel aubio-devel \
        wayland-protocols-devel hyprlang-devel \
        qt6-qtdeclarative-devel qt6-qtbase-devel qt6-qtwayland-devel \
        extra-cmake-modules kf6-kdecoration-devel kf6-kirigami-devel kf6-kcoreaddons-devel \
        nodejs npm
    or begin
        error 'Core package installation failed.'
        exit 1
    end

    # Hyprland: on Fedora 44+ use ashbuk/Hyprland-Fedora COPR
    # On Fedora 41/42, try official repo first, fall back to COPR
    if test "$fedora_version" -ge 43
        log 'Installing Hyprland from COPR...'
        sudo dnf install $dnf_opts \
            hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpicker
        or begin
            error 'Failed to install hyprland packages.'
            exit 1
        end
    else
        if not sudo dnf install $dnf_opts hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpicker
            warn 'Trying Hyprland from COPR...'
            sudo dnf install $dnf_opts hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpicker
            or begin
                error 'Failed to install hyprland packages.'
                exit 1
            end
        end
    end

    # COPR packages (batch — excluding libcava which has its own fallback)
    log 'Installing COPR packages...'
    sudo dnf install $dnf_opts \
        cliphist \
        jetbrains-mono-nerd-fonts caskaydia-cove-nerd-fonts material-symbols-fonts \
        app2unit gpu-screen-recorder \
        lazygit
    or warn 'Some COPR packages failed to install (continuing)'

    # libcava — try COPR first, fall back to source build if no Fedora 44 build available
    if not sudo dnf install $dnf_opts libcava
        warn 'libcava not found in zawertun/scrapyard for this Fedora version. Attempting source build...'
        install_libcava_fallback
    end
end


# ── Font cache ───────────────────────────────────────────────────────────────

function refresh_fonts
    log 'Refreshing font cache...'
    fc-cache -fv
end


# ── Install CLI from upstream source ────────────────────────────────────────

function install_cli
    log 'Building and installing caelestia-cli...'

    set -l workdir (mktemp -d /tmp/caelestia-cli.XXXXXX)
    git clone --depth=1 https://github.com/caelestia-dots/cli.git "$workdir"
    or begin
        error 'Failed to clone caelestia-cli.'
        return 1
    end

    pushd "$workdir"

    # Build wheel
    python3 -m build --wheel
    or begin
        error 'Failed to build caelestia-cli wheel.'
        popd; return 1
    end

    # Install
    sudo python3 -m pip install --break-system-packages dist/*.whl
    or begin
        error 'Failed to install caelestia-cli.'
        popd; return 1
    end

    # Fish completion
    if test -f completions/caelestia.fish
        sudo install -Dm644 completions/caelestia.fish /usr/share/fish/vendor_completions.d/caelestia.fish
    end

    popd
    rm -rf "$workdir"

    if not command -v caelestia >/dev/null
        error "'caelestia' command not found after install."
        return 1
    end

    success 'caelestia-cli installed.'
end


# ── Install Shell from upstream source ──────────────────────────────────────

function install_shell
    log 'Building and installing caelestia-shell...'

    set -l qsh_dir "$config_home/quickshell"
    set -l dest "$qsh_dir/caelestia"
    mkdir -p "$qsh_dir"

    if test -d "$dest/.git"
        log 'Updating existing shell clone...'
        git -C "$dest" pull --ff-only
    else
        log 'Cloning caelestia-shell...'
        git clone --depth=1 https://github.com/caelestia-dots/shell.git "$dest"
        or begin
            error 'Failed to clone caelestia-shell.'
            return 1
        end
    end

    pushd "$dest"

    # Build and install via cmake
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
    or begin
        error 'cmake configure failed.'
        popd; return 1
    end

    cmake --build build
    or begin
        error 'cmake build failed.'
        popd; return 1
    end

    sudo cmake --install build
    or begin
        error 'cmake install failed.'
        popd; return 1
    end

    popd

    # Enable and start the shell systemd service
    systemctl --user enable --now caelestia-shell.service 2>/dev/null
    or warn 'Could not enable caelestia-shell.service (continuing)'

    success 'caelestia-shell installed.'
end


# ── Manual packages ─────────────────────────────────────────────────────────

function install_sass
    log 'Installing dart-sass via npm...'
    sudo npm install -g sass
    or warn 'Failed to install sass (CLI discord theming may not work)'
end

function install_materialyoucolor
    log 'Installing materialyoucolor via pip...'
    sudo python3 -m pip install --break-system-packages materialyoucolor
    or warn 'Failed to install materialyoucolor (color theming may not work)'
end

function install_papirus_folders
    log 'Installing papirus-folders...'
    set -l workdir (mktemp -d /tmp/papirus-folders.XXXXXX)
    git clone --depth=1 https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$workdir"
    pushd "$workdir"
    sudo install -Dm755 papirus-folders /usr/local/bin/papirus-folders
    sudo cp -r src/* /usr/share/icons/Papirus/ 2>/dev/null
    or true
    popd
    rm -rf "$workdir"
    success 'papirus-folders installed.'
end

function install_darkly
    log 'Building and installing darkly Qt style...'
    # Build deps (installed by install_core_packages):
    #   extra-cmake-modules kf6-kdecoration-devel kf6-kirigami-devel kf6-kcoreaddons-devel
    #   cmake ninja-build gcc-c++ qt6-qtbase-devel
    set -l workdir (mktemp -d /tmp/darkly.XXXXXX)
    git clone --depth=1 https://github.com/Bali10050/Darkly.git "$workdir"
    or begin
        warn 'Failed to clone Darkly. Qt theming may be incomplete.'
        return 1
    end
    pushd "$workdir"
    mkdir -p build; cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_QT5=ON -DBUILD_QT6=ON
    or begin
        warn 'cmake configure for darkly failed.'
        popd; return 1
    end
    make -j(nproc)
    or begin
        warn 'darkly build failed.'
        popd; return 1
    end
    sudo make install
    popd
    rm -rf "$workdir"
    success 'darkly Qt style installed.'
end


function install_libcava_fallback
    log 'Building libcava from source (cava)...'
    # Build deps for cava shared library
    sudo dnf install $dnf_opts \
        fftw-devel iniparser-devel SDL2-devel \
        alsa-lib-devel pulseaudio-libs-devel pipewire-devel sndio-devel
    or warn 'Some cava build deps failed (continuing anyway)'
    set -l workdir (mktemp -d /tmp/cava.XXXXXX)
    git clone --depth=1 https://github.com/karlstav/cava.git "$workdir"
    or begin
        warn 'Failed to clone cava. libcava will be missing.'
        return 1
    end
    pushd "$workdir"
    cmake -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DBUILD_SHARED_LIBS=ON
    or begin
        warn 'cava cmake configure failed.'
        popd; return 1
    end
    cmake --build build
    or begin
        warn 'cava build failed.'
        popd; return 1
    end
    sudo cmake --install build
    sudo ldconfig
    popd
    rm -rf "$workdir"
    success 'libcava built and installed from source.'
end


function install_bibata_cursor
    log 'Installing Bibata-Modern-Classic cursor theme...'
    # Check if already installed
    if test -d /usr/share/icons/Bibata-Modern-Classic
        log 'Bibata-Modern-Classic already installed.'
        return 0
    end
    set -l workdir (mktemp -d /tmp/bibata-cursor.XXXXXX)
    # Fetch latest release tarball from GitHub
    set -l release_url (curl -fsSL \
        'https://api.github.com/repos/ful1e5/Bibata_Cursor/releases/latest' \
        | python3 -c "import sys,json; assets=json.load(sys.stdin)['assets']; print(next(a['browser_download_url'] for a in assets if 'Modern-Classic.tar.xz' in a['name']))" \
    )
    or begin
        warn 'Could not fetch Bibata cursor release URL. Skipping cursor install.'
        rm -rf "$workdir"
        return 1
    end
    log "  Downloading $release_url ..."
    curl -fsSL -o "$workdir/bibata.tar.xz" "$release_url"
    or begin
        warn 'Failed to download Bibata cursor. Skipping.'
        rm -rf "$workdir"
        return 1
    end
    tar -xf "$workdir/bibata.tar.xz" -C "$workdir"
    sudo install -d /usr/share/icons/Bibata-Modern-Classic
    sudo cp -r "$workdir/Bibata-Modern-Classic/." /usr/share/icons/Bibata-Modern-Classic/
    rm -rf "$workdir"
    # Update icon cache
    sudo gtk-update-icon-cache -f /usr/share/icons/Bibata-Modern-Classic 2>/dev/null
    or true
    success 'Bibata-Modern-Classic cursor theme installed.'
end


# ── Optional Components ─────────────────────────────────────────────────────

function install_spotify
    log 'Installing Spotify + Spicetify...'
    # Spotify via RPM Fusion or flatpak
    if rpm -q lpf-spotify-client >/dev/null 2>&1
        log 'Spotify already installed.'
    else
        log 'Installing Spotify from RPM Fusion...'
        sudo dnf install $dnf_opts lpf-spotify-client
        or warn 'Could not install Spotify via RPM Fusion. Try: flatpak install flathub com.spotify.Client'
    end

    # Spicetify via upstream script
    if command -v spicetify >/dev/null
        log 'spicetify already installed.'
    else
        log 'Installing spicetify-cli...'
        curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
        or warn 'spicetify install failed.'
    end

    # Spicetify marketplace
    log 'Installing spicetify-marketplace...'
    curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh
    or warn 'spicetify-marketplace install failed.'

    # Config
    spicetify config current_theme caelestia color_scheme caelestia custom_apps marketplace
    spicetify apply

    # Symlink spicetify config
    if confirm_overwrite "$config_home/spicetify"
        ln -s "$dots_dir/spicetify" "$config_home/spicetify"
    end
end

function install_vscodium
    log 'Installing VSCodium...'
    if not command -v codium >/dev/null
        # Use official VSCodium RPM repo
        sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
        printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" \
            | sudo tee /etc/yum.repos.d/vscodium.repo >/dev/null
        sudo dnf install $dnf_opts codium
    end

    # Config
    set -l folder "$config_home/VSCodium/User"
    mkdir -p "$folder"
    if confirm_overwrite "$folder/settings.json"
        ln -s "$dots_dir/vscode/settings.json" "$folder/settings.json"
    end
    if confirm_overwrite "$folder/keybindings.json"
        ln -s "$dots_dir/vscode/keybindings.json" "$folder/keybindings.json"
    end
    if confirm_overwrite "$config_home/codium-flags.conf"
        ln -s "$dots_dir/vscode/flags.conf" "$config_home/codium-flags.conf"
    end
    codium --install-extension "$dots_dir/vscode/caelestia-vscode-integration/caelestia-vscode-integration-"*.vsix
end

function install_vscode
    log 'Installing VSCode...'
    if not command -v code >/dev/null
        # Microsoft RPM repo
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        printf "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" \
            | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
        sudo dnf install $dnf_opts code
    end

    set -l folder "$config_home/Code/User"
    mkdir -p "$folder"
    if confirm_overwrite "$folder/settings.json"
        ln -s "$dots_dir/vscode/settings.json" "$folder/settings.json"
    end
    if confirm_overwrite "$folder/keybindings.json"
        ln -s "$dots_dir/vscode/keybindings.json" "$folder/keybindings.json"
    end
    if confirm_overwrite "$config_home/code-flags.conf"
        ln -s "$dots_dir/vscode/flags.conf" "$config_home/code-flags.conf"
    end
    code --install-extension "$dots_dir/vscode/caelestia-vscode-integration/caelestia-vscode-integration-"*.vsix
end

function install_zed
    log 'Installing Zed editor...'
    if not command -v zed >/dev/null; and not command -v zed-editor >/dev/null
        sudo dnf copr enable $dnf_opts pgdev/zed
        sudo dnf install $dnf_opts zed
    end
    if confirm_overwrite "$config_home/zed"
        ln -s "$dots_dir/zed" "$config_home/zed"
    end
end

function install_zen
    log 'Installing Zen Browser...'
    if not command -v zen-browser >/dev/null
        sudo dnf copr enable $dnf_opts scottames/zen-browser
        sudo dnf install $dnf_opts zen-browser
    end
    set -l chrome "$HOME/.zen/"*"/chrome"
    mkdir -p "$chrome"
    if confirm_overwrite "$chrome/userChrome.css"
        ln -s "$dots_dir/zen/userChrome.css" "$chrome/userChrome.css"
    end
    # Native messaging host
    set -l hosts "$HOME/.mozilla/native-messaging-hosts"
    set -l lib_dir "$HOME/.local/lib/caelestia"
    mkdir -p "$hosts" "$lib_dir"
    cp "$dots_dir/zen/native_app/manifest.json" "$hosts/caelestiafox.json"
    sed -i "s|{{ \$lib }}|$lib_dir|g" "$hosts/caelestiafox.json"
    ln -sf "$dots_dir/zen/native_app/app.fish" "$lib_dir/caelestiafox"
    warn 'Please install the CaelestiaFox extension: https://addons.mozilla.org/en-US/firefox/addon/caelestiafox'
end

function install_uwsm
    log 'Installing UWSM...'
    # solopasha/hyprland COPR is the source for uwsm on all Fedora versions.
    # Ensure it is enabled even if ashbuk/Hyprland-Fedora is being used for Hyprland itself.
    sudo dnf copr enable $dnf_opts solopasha/hyprland
    or warn 'Could not re-enable solopasha/hyprland for uwsm (may already be enabled)'
    sudo dnf install $dnf_opts uwsm
    if confirm_overwrite "$config_home/uwsm"
        ln -s "$dots_dir/uwsm" "$config_home/uwsm"
    end
end


# ── Dotfiles Symlinking ─────────────────────────────────────────────────────

function install_dotfiles
    log 'Installing dotfile symlinks...'

    set -l core_components \
        "hypr" \
        "fish" \
        "foot" \
        "fastfetch" \
        "btop" \
        "micro" \
        "thunar" \
        "starship"

    for comp in $core_components
        set -l src "$dots_dir/$comp"
        set -l dst
        switch $comp
            case thunar
                set dst "$config_home/Thunar"
            case starship
                set dst "$config_home/starship.toml"
                set src "$dots_dir/starship.toml"
            case '*'
                set dst "$config_home/$comp"
        end
        if confirm_overwrite "$dst"
            log "  Linking $comp..."
            mkdir -p (dirname "$dst")
            ln -s "$src" "$dst"
        end
    end
end

function install_firefox_config
    log 'Installing Firefox configuration...'

    # Init firefox if no profiles exist
    if test -f "$dots_dir/firefox/init_firefox.sh"
        bash "$dots_dir/firefox/init_firefox.sh"
    end

    # Install native messaging host
    log 'Installing Firefox native messaging host...'
    sudo install -Dm644 "$dots_dir/firefox/native_app/manifest.json" \
        /usr/lib/mozilla/native-messaging-hosts/caelestiafox.json
    sudo install -Dm755 "$dots_dir/firefox/native_app/app.fish" \
        /usr/lib/caelestia/caelestiafox

    # Symlink userChrome.css and user.js to all Firefox profiles
    for profile in "$HOME/.mozilla/firefox/"*".default"*
        set -l chrome_dir "$profile/chrome"
        mkdir -p "$chrome_dir"
        ln -sf "$dots_dir/firefox/userChrome.css" "$chrome_dir/userChrome.css"
        ln -sf "$dots_dir/firefox/user.js" "$profile/user.js"
    end

    warn 'Please install the CaelestiaFox extension from:'
    warn '  https://addons.mozilla.org/en-US/firefox/addon/caelestiafox'
end


# ── Post-Install Hooks ──────────────────────────────────────────────────────

function post_install_setup
    log 'Running post-install setup...'

    # xdg user dirs
    xdg-user-dirs-update

    # Refresh font cache
    fc-cache -fv

    # Create caelestia config directory
    mkdir -p "$config_home/caelestia"
    touch "$config_home/caelestia/user-config.fish"

    # Initialize scheme if not exists
    if not test -f "$state_home/caelestia/scheme.json"
        log 'Setting initial color scheme...'
        caelestia scheme set -n caelestia
    end

    # Start the shell daemon
    log 'Starting caelestia shell daemon...'
    caelestia shell -d >/dev/null 2>&1
    or warn 'Shell daemon start failed. Try running "caelestia shell -d" manually.'
end


# ── Main ────────────────────────────────────────────────────────────────────

function main
    echo

    # 1. Pre-flight
    enable_coprs
    enable_rpmfusion
    system_update

    # 2. Packages
    install_core_packages

    # Install quickshell explicitly (errornointernet/quickshell COPR)
    # Try the git snapshot first, fall back to stable. Both failures are fatal.
    log 'Installing quickshell...'
    if not sudo dnf install $dnf_opts quickshell-git
        sudo dnf install $dnf_opts quickshell
        or begin
            error 'Failed to install quickshell (tried quickshell-git and quickshell).'
            error 'Ensure errornointernet/quickshell COPR is enabled and has a Fedora 44 build.'
            exit 1
        end
    end

    refresh_fonts

    # 3. CLI and Shell
    install_cli
    install_shell

    # 4. Manual packages (skipped with --core-only)
    if not set -q _flag_core_only
        install_sass
        install_materialyoucolor
        install_papirus_folders
        install_darkly
        install_bibata_cursor
    else
        warn '--core-only: skipping sass, materialyoucolor, papirus-folders, darkly, and cursor theme builds.'
        warn '  Default cursor will be used until Bibata-Modern-Classic is installed manually.'
    end

    # 5. Dotfiles
    install_dotfiles
    install_firefox_config

    # 6. Optional components
    set -q _flag_with_spotify; and install_spotify
    set -q _flag_with_vscodium; and install_vscodium
    set -q _flag_with_vscode; and install_vscode
    set -q _flag_with_zed; and install_zed
    set -q _flag_with_zen; and install_zen
    set -q _flag_with_uwsm; and install_uwsm

    # 7. Post-install
    post_install_setup

    echo
    success '╭─────────────────────────────────────────────────╮'
    success '│     Caelestia installation complete!            │'
    success '│                                                 │'
    success '│  Log out and select Hyprland from your display   │'
    success '│  manager to start using your new desktop.        │'
    success '│                                                 │'
    success '│  Keybinds:                                      │'
    success '│    Super           → Launcher                   │'
    success '│    Super + T       → Terminal (foot)            │'
    success '│    Super + W       → Browser (firefox)          │'
    success '│    Ctrl+Alt+Del    → Session menu               │'
    success '╰─────────────────────────────────────────────────╯'
    echo
end

main
