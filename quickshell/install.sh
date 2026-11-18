#!/usr/bin/env bash
# Shell-Yeah installer — Quickshell config for MangoWM on Arch-based systems.
#
# Interactive by default when run in a terminal: choose the features you want
# and the installer builds the package list from your answers. Core files are
# always created. All old flags still work for automation.
#
# Usage:
#   ./install.sh                  interactive DIY setup (TTY), otherwise auto
#   ./install.sh --diy            force the interactive menu
#   ./install.sh --auto           skip the menu and use defaults
#   ./install.sh --with-optional  auto mode: include optional feature packages
#   ./install.sh --skip-packages  only create/verify files
#   ./install.sh --install-config copy this checkout to ~/.config/quickshell
#   ./install.sh --check          report status, change nothing
#
# When this installer is kept in a git repo outside ~/.config/quickshell, the
# config source is detected automatically and copied to the config dir by
# default (including --auto / piped runs). The repo itself is never used as the
# runtime config dir.
#
# The DIY menu is a little more code than the old flag-only script, but it is
# simpler to use: you pick features by name instead of remembering package
# lists or command-line switches.

set -euo pipefail

INSTALLER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$INSTALLER_DIR"
SOURCE_DIR="$INSTALLER_DIR"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET_DIR="$CONFIG_HOME/quickshell"
# MangoWM ignores XDG_CONFIG_HOME and always reads $HOME/.config/mango.
MANGO_DIR="$HOME/.config/mango"
MANGO_CONF="$MANGO_DIR/config.conf"
MANGO_TOML="$MANGO_DIR/config.toml"

# filled in by detect_mango_config():
#   MANGO_KIND        "conf", "toml", or "" when no config exists
#   MANGO_CONFIG_FILE the file MangoWM will actually load
MANGO_KIND=""
MANGO_CONFIG_FILE=""

SKIP_PACKAGES=0
WITH_OPTIONAL=0
INSTALL_CONFIG=0
CHECK_ONLY=0
INTERACTIVE=0
INTERACTIVE_SET=0
AUR_HELPER="manual"
PICKER_PKG=""
MENU_WELCOME_SHOWN=0

for arg in "$@"; do
    case "$arg" in
        --diy|--interactive) INTERACTIVE=1; INTERACTIVE_SET=1 ;;
        --auto|--no-interactive) INTERACTIVE=0; INTERACTIVE_SET=1 ;;
        --skip-packages) SKIP_PACKAGES=1 ;;
        --with-optional) WITH_OPTIONAL=1 ;;
        --install-config) INSTALL_CONFIG=1 ;;
        --check) CHECK_ONLY=1 ;;
        -h|--help)
            awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
            exit 0
            ;;
        *)
            printf 'unknown option: %s\n' "$arg" >&2
            exit 2
            ;;
    esac
done

# Without an explicit flag, use the menu only when a human is at the terminal.
if (( !INTERACTIVE_SET )); then
    if [[ -t 0 ]]; then
        INTERACTIVE=1
    fi
fi

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
# Portal daemons install to /usr/lib (not on PATH), so detect them by package.
have_pkg() { command -v pacman >/dev/null 2>&1 && pacman -Qq "$1" >/dev/null 2>&1; }
as_root() {
    if ((EUID == 0)); then
        "$@"
    else
        sudo "$@"
    fi
}

first_available() {
    local cmd
    for cmd in "$@"; do
        if have "$cmd"; then
            printf '%s' "$cmd"
            return 0
        fi
    done
    return 1
}

# The installer may live in a git repo alongside README.md instead of inside
# ~/.config/quickshell. Find the QML config source without confusing it with the
# runtime directory.
detect_config_source() {
    SOURCE_DIR=""

    if [[ -f "$SCRIPT_DIR/shell.qml" ]]; then
        SOURCE_DIR="$SCRIPT_DIR"
    elif [[ -f "$SCRIPT_DIR/quickshell/shell.qml" ]]; then
        SOURCE_DIR="$SCRIPT_DIR/quickshell"
    elif [[ -f "$TARGET_DIR/shell.qml" ]]; then
        SOURCE_DIR="$TARGET_DIR"
    else
        return 1
    fi
}

detect_aur_helper() {
    if have paru; then
        AUR_HELPER=paru
    elif have yay; then
        AUR_HELPER=yay
    else
        AUR_HELPER=manual
    fi
}

# MangoWM loads ~/.config/mango/config.conf when it exists and only falls back
# to config.toml otherwise (see src/config/load.c). Mirror that precedence so
# the installer edits the file the compositor actually reads.
detect_mango_config() {
    MANGO_KIND=""
    MANGO_CONFIG_FILE=""

    if [[ -f "$MANGO_CONF" ]]; then
        MANGO_KIND="conf"
        MANGO_CONFIG_FILE="$MANGO_CONF"
        if [[ -f "$MANGO_TOML" ]]; then
            warn "Both config.conf and config.toml exist; MangoWM loads config.conf."
            warn "Edits will go to $MANGO_CONF and config.toml will be ignored."
        fi
    elif [[ -f "$MANGO_TOML" ]]; then
        MANGO_KIND="toml"
        MANGO_CONFIG_FILE="$MANGO_TOML"
    fi
}

# Core package: the shell itself. Core files are always created regardless of
# which optional feature groups are selected.
REPO_CORE=(
    quickshell
)

# Feature groups shown in the DIY menu. Each group maps to the packages it
# needs; selecting a group adds those packages to the install list.
FEATURE_IDS=(
    wm
    clipboard
    brightness
    theme
    screenshot
    portal
    audio
    network
    bluetooth
    power
    secrets
    picker
)

declare -A FEATURE_LABEL=(
    [wm]="MangoWM + mmsg (window manager / IPC)"
    [clipboard]="Clipboard history (cliphist + wl-clipboard)"
    [brightness]="Brightness slider (brightnessctl + ddcutil)"
    [theme]="Pywal theming + Meslo Nerd font"
    [screenshot]="Region screenshots (grim + slurp)"
    [portal]="Screencast portals (xdg-desktop-portal*)"
    [audio]="Audio controls (libpulse + wireplumber)"
    [network]="Network widget (NetworkManager)"
    [bluetooth]="Bluetooth widget (bluez-utils)"
    [power]="Power / idle reporting (upower)"
    [secrets]="Secret portal (gnome-keyring)"
    [picker]="Fallback dmenu picker (rofi/wofi/etc.)"
)

declare -A FEATURE_REPO=(
    [wm]=""
    [clipboard]="cliphist wl-clipboard"
    [brightness]="ddcutil brightnessctl"
    [theme]="ttf-meslo-nerd"
    [screenshot]="grim slurp"
    [portal]="xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr"
    [audio]="libpulse wireplumber"
    [network]="networkmanager"
    [bluetooth]="bluez-utils"
    [power]="upower"
    [secrets]="gnome-keyring"
    [picker]=""
)

declare -A FEATURE_AUR=(
    [wm]="mangowm-git"
    [clipboard]=""
    [brightness]=""
    [theme]="python-pywal16-git"
    [screenshot]=""
    [portal]=""
    [audio]=""
    [network]=""
    [bluetooth]=""
    [power]=""
    [secrets]=""
    [picker]=""
)

# Defaults match the old script: core runtime + WM + clipboard + brightness +
# pywal + portals. Extra widgets are only installed with --with-optional or when
# selected in the DIY menu.
declare -A FEATURE_DEFAULT=(
    [wm]=1
    [clipboard]=1
    [brightness]=1
    [theme]=1
    [screenshot]=0
    [portal]=1
    [audio]=0
    [network]=0
    [bluetooth]=0
    [power]=0
    [secrets]=0
    [picker]=0
)

OPTIONAL_FEATURE_IDS=(
    screenshot
    audio
    network
    bluetooth
    power
    secrets
)

declare -A SELECTED=()
SELECTED_REPO=()
SELECTED_AUR=()

load_defaults() {
    local id
    for id in "${FEATURE_IDS[@]}"; do
        SELECTED[$id]=${FEATURE_DEFAULT[$id]}
    done
    if (( WITH_OPTIONAL )); then
        for id in "${OPTIONAL_FEATURE_IDS[@]}"; do
            SELECTED[$id]=1
        done
    fi
}

dedupe() {
    local -n arr="$1"
    local seen=" " item
    local -a out=()
    for item in "${arr[@]}"; do
        [[ "$seen" == *" $item "* ]] && continue
        seen+="$item "
        out+=("$item")
    done
    arr=("${out[@]}")
}

choose_picker() {
    local detected answer
    detected="$(first_available rofi wofi dmenu fuzzel bemenu || true)"
    PICKER_PKG=""

    if (( !INTERACTIVE )); then
        # --with-optional used to leave the picker to the user; keep that
        # behavior unless the DIY menu explicitly selects a package.
        return 0
    fi

    printf '\n'
    say "Fallback picker"
    printf '  Used when Quickshell is not running (portal chooser fallback).\n'
    printf '  Detected: %s\n' "${detected:-none}"
    printf '  Package:  rofi | wofi | dmenu | fuzzel | bemenu | none\n'
    read -rp '  Install which one? [none]: ' answer || answer=""
    answer="${answer,,}"

    case "$answer" in
        rofi|wofi|dmenu|fuzzel|bemenu) PICKER_PKG="$answer" ;;
        *) PICKER_PKG="" ;;
    esac
}

needs_aur() {
    local id
    for id in "${FEATURE_IDS[@]}"; do
        if (( ${SELECTED[$id]:-0} )) && [[ -n "${FEATURE_AUR[$id]}" ]]; then
            return 0
        fi
    done
    return 1
}

choose_aur_helper() {
    local answer
    if (( !INTERACTIVE )); then
        return 0
    fi

    printf '\n'
    say "AUR helper"
    printf '  Some selected features need AUR packages. paru/yay are not installed\n'
    printf '  by this script; choose "manual" and install them yourself if needed.\n'
    printf '  Current: %s\n' "$AUR_HELPER"
    read -rp '  Use [paru/yay/manual]: ' answer || answer=""
    answer="${answer,,}"

    case "$answer" in
        paru|yay) AUR_HELPER="$answer" ;;
        manual|'') AUR_HELPER="${answer:-$AUR_HELPER}" ;;
        *) warn "Unknown helper '$answer'; keeping $AUR_HELPER." ;;
    esac
}

show_menu() {
    local i=1 id mark
    printf '\n'
    if (( !MENU_WELCOME_SHOWN )); then
        say "Welcome to Shell-Yeah."
        printf 'Pick the pieces you want. Core files + Quickshell are always included.\n\n'
        MENU_WELCOME_SHOWN=1
    else
        say "Shell-Yeah DIY setup"
        printf '\n'
    fi
    printf '  %-3s %-58s %s\n' '#' 'Feature' 'Selected'
    printf '  %-3s %-58s %s\n' '0' 'Core: shell package, state, PAM, wallpaper folders' 'yes'

    for id in "${FEATURE_IDS[@]}"; do
        if (( ${SELECTED[$id]:-0} )); then
            mark='yes'
        else
            mark='no'
        fi
        printf '  %-3s %-58s %s\n' "$i" "${FEATURE_LABEL[$id]}" "$mark"
        ((i++))
    done

    printf '\n'
    printf '  Type numbers to toggle (e.g. 2,5,7), a=all, n=core only, d=defaults.\n'
    printf '  Press Enter to continue.\n'
}

configure_features() {
    local answer token id
    local -a nums

    while true; do
        show_menu
        read -rp '  Your choice: ' answer || answer=""
        answer="${answer//[[:space:]]/}"
        [[ -z "$answer" ]] && break

        case "${answer,,}" in
            a)
                for id in "${FEATURE_IDS[@]}"; do SELECTED[$id]=1; done
                ;;
            n)
                for id in "${FEATURE_IDS[@]}"; do SELECTED[$id]=0; done
                ;;
            d)
                load_defaults
                ;;
            *)
                IFS=',' read -ra nums <<< "$answer"
                for token in "${nums[@]}"; do
                    if [[ "$token" =~ ^[0-9]+$ ]] \
                        && (( token >= 1 && token <= ${#FEATURE_IDS[@]} )); then
                        id="${FEATURE_IDS[token - 1]}"
                        if (( ${SELECTED[$id]:-0} )); then
                            SELECTED[$id]=0
                        else
                            SELECTED[$id]=1
                        fi
                    else
                        warn "Invalid choice: $token"
                    fi
                done
                ;;
        esac
    done

    if (( ${SELECTED[picker]:-0} )); then
        choose_picker
    fi
    if needs_aur; then
        choose_aur_helper
    fi
}

print_selection_summary() {
    local id
    say "Selected features:"
    printf '  core    Core files + Quickshell\n'
    for id in "${FEATURE_IDS[@]}"; do
        printf '  %-10s %-58s %s\n' "$id" "${FEATURE_LABEL[$id]}" \
            "$( (( ${SELECTED[$id]:-0} )) && printf yes || printf no )"
    done
    if needs_aur; then
        printf '  AUR helper: %s\n' "$AUR_HELPER"
    fi
    if [[ -n "$PICKER_PKG" ]]; then
        printf '  Fallback picker package: %s\n' "$PICKER_PKG"
    fi
    if (( SKIP_PACKAGES )); then
        printf '  Package installation: skipped\n'
    fi
}

collect_packages() {
    local id pkg
    SELECTED_REPO=("${REPO_CORE[@]}")
    SELECTED_AUR=()

    for id in "${FEATURE_IDS[@]}"; do
        (( ${SELECTED[$id]:-0} )) || continue

        if [[ -n "${FEATURE_REPO[$id]}" ]]; then
            read -ra pkg <<< "${FEATURE_REPO[$id]}"
            SELECTED_REPO+=("${pkg[@]}")
        fi
        if [[ -n "${FEATURE_AUR[$id]}" ]]; then
            read -ra pkg <<< "${FEATURE_AUR[$id]}"
            SELECTED_AUR+=("${pkg[@]}")
        fi
    done

    [[ -n "$PICKER_PKG" ]] && SELECTED_REPO+=("$PICKER_PKG")
    dedupe SELECTED_REPO
    dedupe SELECTED_AUR
}

maybe_copy_prompt() {
    local answer default
    (( INTERACTIVE )) || return 0
    [[ "$SOURCE_DIR" != "$TARGET_DIR" ]] || return 0

    # Copying is already the default; this prompt is only a confirmation.
    if (( INSTALL_CONFIG )); then
        default="Y/n"
    else
        default="y/N"
    fi

    printf '\n'
    say "Config source: $SOURCE_DIR"
    printf '  Runtime dir:  %s\n' "$TARGET_DIR"
    read -rp "Copy the config to $TARGET_DIR? [$default]: " answer || answer=""
    answer="${answer,,}"

    case "$answer" in
        y|yes|'') INSTALL_CONFIG=1 ;;
        *)        INSTALL_CONFIG=0 ;;
    esac
}

maybe_install_prompt() {
    local answer
    if (( INTERACTIVE )) && (( SKIP_PACKAGES == 0 )); then
        read -rp 'Install the selected packages now? [Y/n]: ' answer || answer=""
        [[ "$answer" =~ ^[Nn] ]] && SKIP_PACKAGES=1
    fi
}

install_packages() {
    local missing=()
    local pkg
    local -a pkgs=()

    collect_packages

    if ! have pacman; then
        warn "pacman not found; this config targets Arch-based systems."
        warn "Install these manually: ${SELECTED_REPO[*]} ${SELECTED_AUR[*]}"
        return 0
    fi

    for pkg in "${SELECTED_REPO[@]}"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done

    if ((${#missing[@]})); then
        say "Installing repo packages: ${missing[*]}"
        as_root pacman -S --needed --noconfirm "${missing[@]}"
    else
        say "Repo packages already installed."
    fi

    local aur_missing=()
    for pkg in "${SELECTED_AUR[@]}"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 || aur_missing+=("$pkg")
    done

    if ((${#aur_missing[@]})); then
        if [[ "$AUR_HELPER" != manual ]] && have "$AUR_HELPER"; then
            say "Installing AUR packages: ${aur_missing[*]}"
            "$AUR_HELPER" -S --needed --noconfirm "${aur_missing[@]}"
        else
            warn "AUR packages missing and no usable paru/yay found: ${aur_missing[*]}"
            warn "Install them manually — mangowm-git provides mango and mmsg,"
            warn "python-pywal16-git provides wal."
        fi
    fi
}

copy_config() {
    if [[ "$SOURCE_DIR" == "$TARGET_DIR" ]]; then
        return 0
    fi

    say "Copying config from $SOURCE_DIR to $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    if have rsync; then
        rsync -a --exclude '.git' --exclude 'state/' "$SOURCE_DIR/" "$TARGET_DIR/"
    else
        (cd "$SOURCE_DIR" && tar --exclude=.git --exclude=state -cf - .) \
            | (cd "$TARGET_DIR" && tar -xf -)
    fi
}

ensure_state() {
    mkdir -p "$SCRIPT_DIR/state" "$SCRIPT_DIR/walls"

    if [[ ! -f "$SCRIPT_DIR/state/state.json" ]]; then
        printf '{}\n' > "$SCRIPT_DIR/state/state.json"
        say "Created $SCRIPT_DIR/state/state.json"
    fi

    local folder
    # Theme folders declared in modules/themeing/ThemeState.qml. Created up
    # front so the wallpaper model never points at a missing directory; themes
    # without images are blocked by the shell at runtime.
    for folder in \
        dark light gruvbox-dark gruvbox-light everforest everforest-light \
        nord nord-light tokyo-night tokyo-night-light kanagawa rose-pine \
        catppuccin-mocha pink; do
        mkdir -p "$SCRIPT_DIR/walls/$folder"
    done
}

ensure_pam() {
    local f="$SCRIPT_DIR/pam/password.conf"
    if [[ -f "$f" ]]; then
        return 0
    fi
    mkdir -p "$SCRIPT_DIR/pam"
    printf 'auth required pam_unix.so\n' > "$f"
    say "Created $f"
}

write_mango_wal() {
    local f="$1"

    cat > "$f" <<'EOF'
#!/bin/bash
# Translate pywal's colors into MangoWM's border colors.
# Generated by the Shell-Yeah installer; re-running install.sh regenerates
# this file, so keep custom logic in a separate script.
#
# MangoWM prefers config.conf over config.toml, so the active file is detected
# at runtime. Both formats use the same color key names.

set -euo pipefail

[[ -r ~/.cache/wal/colors ]] || exit 0

mapfile -t walcolors <~/.cache/wal/colors

to_mango() {
  echo "0x${1:1:6}ff"
}

keys=(root_color border_color focus_color urgent_color drop_color split_color \
      maximized_screen_color scratchpad_color global_color overlay_color)

declare -A colors=(
  [root_color]="$(to_mango "${walcolors[0]}")"
  [border_color]="$(to_mango "${walcolors[0]}")"
  [focus_color]="$(to_mango "${walcolors[1]}")"
  [urgent_color]="$(to_mango "${walcolors[9]}")"
  [drop_color]="$(to_mango "${walcolors[1]}")"
  [split_color]="$(to_mango "${walcolors[2]}")"
  [maximized_screen_color]="$(to_mango "${walcolors[3]}")"
  [scratchpad_color]="$(to_mango "${walcolors[4]}")"
  [global_color]="$(to_mango "${walcolors[5]}")"
  [overlay_color]="$(to_mango "${walcolors[6]}")"
)

if [[ -f "$HOME/.config/mango/config.conf" ]]; then
  conf="$HOME/.config/mango/config.conf"
  for key in "${keys[@]}"; do
    value="${colors[$key]}"
    if grep -q "^${key}=" "$conf"; then
      sed -i "s|^${key}=.*|${key}=${value}|" "$conf"
    else
      printf '%s=%s\n' "$key" "$value" >> "$conf"
    fi
  done
else
  toml="$HOME/.config/mango/bordercolor.toml"
  : > "$toml"
  for key in "${keys[@]}"; do
    printf '%s = %s\n' "$key" "${colors[$key]}" >> "$toml"
  done
fi

if command -v mmsg >/dev/null 2>&1; then
  mmsg dispatch reload_config >/dev/null 2>&1 || true
fi
EOF
    chmod +x "$f"
}

ensure_mango_wal() {
    local f="$MANGO_DIR/mango-wal.sh"
    mkdir -p "$MANGO_DIR"

    if [[ ! -f "$f" ]]; then
        write_mango_wal "$f"
        say "Created $f"
        return 0
    fi

    # Only touch files that came from this installer. A hand-written hook
    # without the header is left alone so local changes are not clobbered.
    if grep -Fq 'Generated by the Shell-Yeah installer' "$f" \
        || grep -Fq 'Generated by the quickshell install script' "$f" \
        || grep -Fq 'cat >~/.config/mango/bordercolor.toml' "$f"; then
        write_mango_wal "$f"
        say "Updated $f"
    else
        say "Left custom $f untouched."
    fi
}

ensure_mango_rule() {
    if [[ -z "$MANGO_KIND" ]]; then
        warn "No MangoWM config found (config.conf or config.toml) — skipping the Settings window rule."
        return 0
    fi

    local f="$MANGO_CONFIG_FILE"

    if [[ "$MANGO_KIND" == "toml" ]]; then
        if grep -Fq 'title = "^Settings$"' "$f"; then
            local tmp
            tmp="$(mktemp)"
            # Add any missing keys inside the Settings rule block only; never
            # overwrite values the user may have tuned (size, monitor, etc.).
            awk '
                function flush() {
                    if (inblock && settings) {
                        if (!seen_f) print "is_floating = 1"
                        if (!seen_w) print "width = 1200"
                        if (!seen_h) print "height = 800"
                    }
                }
                /^\[/ {
                    flush()
                    inblock = ($0 ~ /^\[\[rule\.window_rule\]\]/)
                    if (inblock) { settings = 0; seen_f = 0; seen_w = 0; seen_h = 0 }
                    print; next
                }
                inblock && /^[[:space:]]*title[[:space:]]*=/ {
                    if ($0 ~ /\^Settings\$/) settings = 1
                    print; next
                }
                inblock && settings && /^[[:space:]]*is_floating[[:space:]]*=/ {
                    seen_f = 1; print; next
                }
                inblock && settings && /^[[:space:]]*width[[:space:]]*=/ {
                    seen_w = 1; print; next
                }
                inblock && settings && /^[[:space:]]*height[[:space:]]*=/ {
                    seen_h = 1; print; next
                }
                { print }
                END { flush() }
            ' "$f" > "$tmp" && mv "$tmp" "$f"
            say "Updated the Settings window rule in $f"
            return 0
        fi

        cat >> "$f" <<'EOF'

# quickshell's Settings window is a regular xdg-toplevel; float it instead of
# letting the tiling layout swallow it
[[rule.window_rule]]
app_id = "org.quickshell"
title = "^Settings$"
is_floating = 1
width = 1200
height = 800
EOF
    else
        if grep -Fq 'title:^Settings$' "$f"; then
            # Update only the three fields we own; preserve any other fields
            # (monitor, workspace, etc.) the user added to the rule.
            local tmp
            tmp="$(mktemp)"
            awk -F',' '
                /^window_rule=/ && /title:\^Settings\$/ {
                    prefix = "window_rule=";
                    n = split(substr($0, length(prefix) + 1), part, ",");
                    out = ""; has_f = 0; has_w = 0; has_h = 0;
                    for (i = 1; i <= n; i++) {
                        f = part[i]
                        if (f ~ /^is_floating:/) { f = "is_floating:1"; has_f = 1 }
                        else if (f ~ /^width:/)  { f = "width:1200";   has_w = 1 }
                        else if (f ~ /^height:/) { f = "height:800";   has_h = 1 }
                        out = out (i > 1 ? "," : "") f
                    }
                    if (!has_f) out = out ",is_floating:1"
                    if (!has_w) out = out ",width:1200"
                    if (!has_h) out = out ",height:800"
                    print prefix out; next
                }
                { print }
            ' "$f" > "$tmp" && mv "$tmp" "$f"
            say "Updated the Settings window rule in $f"
            return 0
        fi

        cat >> "$f" <<'EOF'

# quickshell's Settings window is a regular xdg-toplevel; float it instead of
# letting the tiling layout swallow it
window_rule=is_floating:1,app_id:org.quickshell,title:^Settings$,width:1200,height:800
EOF
    fi

    say "Added the Settings window rule to $f"
}

ensure_mango_keybind() {
    if [[ -z "$MANGO_KIND" ]]; then
        warn "No MangoWM config found (config.conf or config.toml) — skipping the screenshot keybind."
        return 0
    fi

    if [[ "$MANGO_KIND" == "conf" ]]; then
        local f="$MANGO_CONFIG_FILE"

        if grep -Fq 'screenshot-qs region' "$f"; then
            sed -i -E 's@^(bind=[^,]*, *[^,]*, *spawn,).*screenshot-qs region.*$@\1qs ipc call screenshot-qs region@' "$f"
            say "Updated the screenshot keybind in $f"
            return 0
        fi

        printf '\n# region screenshot (grim + slurp)\n%s\n' \
            'bind=NONE,Print,spawn,qs ipc call screenshot-qs region' >> "$f"
        say "Added the screenshot keybind to $f"
        return 0
    fi

    local f="$MANGO_DIR/binds.toml"
    local bind='Print = "spawn,qs ipc call screenshot-qs region"'

    if [[ ! -f "$f" ]]; then
        warn "No $f found — skipping the screenshot keybind (install MangoWM, then re-run)."
        return 0
    fi

    if grep -Fq 'screenshot-qs region' "$f"; then
        sed -i -E 's@^([^=]+=)[[:space:]]*.*screenshot-qs region.*$@\1 "spawn,qs ipc call screenshot-qs region"@' "$f"
        say "Updated the screenshot keybind in $f"
        return 0
    fi

    # If Print is already bound to something else, update that line instead of
    # appending a duplicate TOML key (which would break the whole config).
    if grep -Eq '^[[:space:]]*"?Print"?[[:space:]]*=' "$f"; then
        sed -i -E 's@^([[:space:]]*"?Print"?[[:space:]]*=[[:space:]]*).*$@\1"spawn,qs ipc call screenshot-qs region"@' "$f"
        say "Updated the Print keybind in $f"
        return 0
    fi

    if ! grep -Eq '^\[bind\.default\]' "$f"; then
        warn "$f has no [bind.default] table — add this bind manually:"
        warn "  $bind"
        return 0
    fi

    # insert inside the existing table; appending a second [bind.default]
    # header would make the file invalid TOML
    local tmp
    tmp="$(mktemp)"
    awk -v bind="$bind" '
        { print }
        /^\[bind\.default\]/ && !done {
            print "# region screenshot (grim + slurp)"
            print bind
            done = 1
        }
    ' "$f" > "$tmp" && mv "$tmp" "$f"
    say "Added the screenshot keybind to $f"
}

ensure_dmenu_bridge() {
    local bin="$HOME/.local/bin/qs-dmenu"
    mkdir -p "$HOME/.local/bin"

    # Regenerate our own shim, but leave a hand-written file with the same name
    # alone so local customizations aren't clobbered on re-run.
    if [[ ! -f "$bin" ]] || ! grep -Fq '# qs-dmenu v2' "$bin"; then
        cat > "$bin" <<'EOF'
#!/bin/sh
# qs-dmenu v2
# qs-dmenu — dmenu-protocol bridge to Quickshell's DmenuPicker.
#
# Apps like xdg-desktop-portal-wlr pipe a newline-separated list of options to
# a chooser's stdin and read the chosen line back from stdout. This shim asks
# Quickshell to show them in a native picker, blocks until the user picks, and
# prints the line — so the caller can't tell it isn't rofi. Falls back to the
# first available dmenu-style chooser when Quickshell isn't running.

PROMPT="Select"
while [ "$#" -gt 0 ]; do
    case "$1" in
        -p|--prompt) PROMPT="$2"; shift 2 ;;
        -p*)         PROMPT="${1#-p}"; shift ;;
        *)           shift ;;
    esac
done

DIR=$(mktemp -d /tmp/qs-dmenu.XXXXXX) || exit 1
trap 'rm -rf "$DIR"' EXIT
trap 'exit 1' HUP INT TERM

cat > "$DIR/items"
mkfifo "$DIR/reply"

FALLBACK() {
    if command -v rofi >/dev/null 2>&1; then
        cat "$DIR/items" | rofi -dmenu -p "$PROMPT"
    elif command -v wofi >/dev/null 2>&1; then
        cat "$DIR/items" | wofi --dmenu --prompt "$PROMPT"
    elif command -v dmenu >/dev/null 2>&1; then
        cat "$DIR/items" | dmenu -p "$PROMPT"
    elif command -v fuzzel >/dev/null 2>&1; then
        cat "$DIR/items" | fuzzel --dmenu --prompt "$PROMPT"
    elif command -v bemenu >/dev/null 2>&1; then
        cat "$DIR/items" | bemenu -p "$PROMPT"
    else
        printf '%s\n' "qs-dmenu: no dmenu-style chooser available" >&2
        return 127
    fi
}

if ! qs ipc call dmenu-picker pick "$DIR" "$PROMPT" >/dev/null 2>&1; then
    FALLBACK
    exit $?
fi

RESULT=$(timeout 60 cat "$DIR/reply" 2>/dev/null)
STATUS=$?
if [ "$STATUS" -ne 0 ]; then
    FALLBACK
    exit $?
fi

[ -n "$RESULT" ] && printf '%s\n' "$RESULT"
exit 0
EOF
        chmod +x "$bin"
        say "Created $bin"
    else
        say "Left custom $bin untouched."
    fi

    # Route xdg-desktop-portal-wlr's screen picker at the shim. Unquoted heredoc
    # so $HOME expands to the installing user's directory.
    local cfg="$CONFIG_HOME/xdg-desktop-portal-wlr/config"
    mkdir -p "$(dirname "$cfg")"
    # Match the actual chooser value, not just a comment: on a different account
    # a stale /home/<other-user> path must be regenerated for this $HOME.
    local expected="chooser_cmd=$HOME/.local/bin/qs-dmenu -p \"Select a screen to capture\""
    if [[ ! -f "$cfg" ]] || ! grep -Fqx "$expected" "$cfg"; then
        cat > "$cfg" <<EOF
[screencast]
# Route the monitor/output chooser through Quickshell's generic dmenu picker
# instead of rofi. xdg-desktop-portal-wlr pipes outputs to qs-dmenu's stdin and
# reads the chosen line back from stdout.
chooser_type=dmenu
chooser_cmd=$HOME/.local/bin/qs-dmenu -p "Select a screen to capture"
EOF
        say "Created $cfg"
    else
        say "Left custom $cfg untouched."
    fi
}

report() {
    local missing=()
    local cmd

    for cmd in mango mmsg qs cliphist wl-copy wl-paste systemctl; do
        have "$cmd" || missing+=("$cmd")
    done
    have wal || warn "wal not found — wallpaper color extraction will be skipped."
    for pkg in xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr; do
        have_pkg "$pkg" || warn "$pkg not installed — screencast/output selection will not work."
    done
    have_pkg gnome-keyring || warn "gnome-keyring not installed — the Secret portal will be unavailable."
    if ! have rofi && ! have wofi && ! have dmenu && ! have fuzzel && ! have bemenu; then
        warn "No dmenu-style chooser found — the portal/fallback picker will not work."
    fi

    if ((${#missing[@]})); then
        warn "Missing required commands: ${missing[*]}"
    else
        say "Required commands present."
    fi

    if [[ -n "$MANGO_KIND" ]]; then
        say "MangoWM config: $MANGO_CONFIG_FILE ($MANGO_KIND)"
    else
        warn "No MangoWM config found under $MANGO_DIR (config.conf or config.toml)."
        warn "The Settings window rule, screenshot keybind and pywal hook cannot be added."
    fi

    if have brightnessctl && brightnessctl --class=backlight -m >/dev/null 2>&1; then
        say "Brightness backend: brightnessctl (internal panel)."
    elif have ddcutil; then
        if ddcutil detect --brief 2>/dev/null | grep -q '/dev/i2c-'; then
            say "Brightness backend: ddcutil (external DDC/CI monitor)."
        else
            warn "ddcutil is installed but no DDC/CI display was detected."
            warn "The brightness slider will be disabled at runtime."
        fi
    else
        warn "No brightness backend found (brightnessctl or ddcutil)."
        warn "The brightness slider will be disabled at runtime."
    fi

    for cmd in pactl wpctl nmcli bluetoothctl upower grim slurp; do
        have "$cmd" || warn "$cmd not found — the matching widget/feature will be unavailable."
    done

    if [[ ! -f "$SCRIPT_DIR/shell.qml" ]]; then
        warn "shell.qml is missing from $SCRIPT_DIR — the config cannot start."
    fi
    if [[ ! -f "$SCRIPT_DIR/state/state.json" ]]; then
        warn "state/state.json is missing."
    fi
    if [[ ! -f "$SCRIPT_DIR/pam/password.conf" ]]; then
        warn "pam/password.conf is missing — unlocking will not work."
    fi

    if [[ -x "$HOME/.local/bin/qs-dmenu" ]]; then
        say "App picker bridge: $HOME/.local/bin/qs-dmenu"
    else
        warn "qs-dmenu is missing — app-invoked menus will fall back to rofi."
    fi

    if [[ -f "$CONFIG_HOME/xdg-desktop-portal-wlr/config" ]]; then
        say "Screencast chooser: $CONFIG_HOME/xdg-desktop-portal-wlr/config"
    else
        warn "xdg-desktop-portal-wlr config is missing — OBS will use the default chooser."
    fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

say "Shell-Yeah installer: $INSTALLER_DIR"
detect_mango_config
detect_aur_helper
load_defaults

if ! detect_config_source; then
    if (( CHECK_ONLY )); then
        warn "Could not find shell.qml beside install.sh, under ./quickshell, or in $TARGET_DIR."
        SOURCE_DIR="$TARGET_DIR"
    else
        die "Could not find shell.qml beside install.sh, under ./quickshell, or in $TARGET_DIR."
    fi
fi

if ((CHECK_ONLY)); then
    SCRIPT_DIR="$TARGET_DIR"
    report
    exit 0
fi

# A git checkout is a source tree, not the runtime config dir. Copy by default
# so --auto, piped, and other non-TTY runs also create files in the right place.
if [[ "$SOURCE_DIR" != "$TARGET_DIR" ]]; then
    INSTALL_CONFIG=1
fi

if ((INTERACTIVE)); then
    configure_features
    print_selection_summary
    maybe_copy_prompt
    maybe_install_prompt
fi

if ((INSTALL_CONFIG)); then
    copy_config
fi

# From here on, every generated file belongs in the real config directory.
SCRIPT_DIR="$TARGET_DIR"

if [[ ! -f "$SCRIPT_DIR/shell.qml" ]]; then
    warn "No shell.qml in $SCRIPT_DIR. Shell-Yeah will not start until the config is copied there."
fi

if ((SKIP_PACKAGES == 0)); then
    install_packages
fi

ensure_state
ensure_pam
ensure_dmenu_bridge
ensure_mango_wal
ensure_mango_rule
ensure_mango_keybind
report

say "Done. Shell-Yeah reloads on file changes; restart it with: qs -c $SCRIPT_DIR"
