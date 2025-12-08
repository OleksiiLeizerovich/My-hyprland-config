#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Path to the repository root (where this script is located)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}[INFO] Starting Hyprland setup...${NC}"

# --- BLOCK 1: Variables ---

DEPENDENCIES=(
    # --- Core Hyprland & System ---
    "hyprland"
    "git"
    "sddm"              # Display Manager
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"

    # --- UI & Theming ---
    "kitty"             # Terminal
    "wofi"              # Application Launcher
    "waybar"            # Status Bar
    "swww"              # Wallpaper Daemon
    "waypaper"          # Wallpaper Manager GUI
    "swaync"            # Notification Center
    "hyprlock"          # Lock screen
    "wlogout"           # Power Menu
    "hypridle"          # Idle daemon
    "qt5-wayland"       "qt6-wayland" "qt6ct" "nwg-look"

    # --- Utilities ---
    "dolphin"           # File Manager
    "kate"              # Text Editor (KDE)
    "ark"               # Archive Manager (KDE)
    "7zip"              # Backend for .7z files (Required for Ark)
    "unrar"             # Backend for .rar files (Required for Ark)

    "kdeconnect"        # Phone integration
    "polkit-gnome"      # Authentication Agent
    "gammastep"         # Blue light filter
    "wl-clipboard"      # Clipboard (Required for bemoji)
    "cliphist"          # Clipboard history
    "grim" "slurp" "satty" # Screenshot tools
    "jq"                # JSON processor
    "btop"              # System monitor
    "brightnessctl"     # Brightness
    "playerctl"         # Media control
    "bemoji-git"        # Emoji Picker (AUR)

    # --- Waybar Specific ---
    "pavucontrol" "blueman" "networkmanager" "pacman-contrib"
    "python-pywal"      # Pywal
    "hyprpicker"        # Color picker
    "imagemagick"       # Image manipulation
    "libnotify"         # Notifications

    # --- Fonts & Icons ---
    "ttf-nerd-fonts-symbols"
    "apple-fonts"                # SF Pro Display (AUR)
    "ttf-sourcecodepro-nerd"     # Correct package name for Arch
    "ttf-jetbrains-mono-nerd"
    "noto-fonts"                 # Base fonts
    "noto-fonts-emoji"           # Emoji fonts
)

# --- BLOCK 2: Functions ---

install_dependencies() {
    echo -e "${BLUE}[INFO] Installing dependencies...${NC}"

    if command -v yay &> /dev/null; then AUR_HELPER="yay"; elif command -v paru &> /dev/null; then AUR_HELPER="paru"; else echo "Error: AUR helper missing."; exit 1; fi

    for PACKAGE in "${DEPENDENCIES[@]}"; do
        if ! pacman -Qi "$PACKAGE" &> /dev/null; then
            echo -e "Installing: $PACKAGE"
            $AUR_HELPER -S --needed --noconfirm "$PACKAGE"
        else
            echo -e "${GREEN}[OK] $PACKAGE installed.${NC}"
        fi
    done
}

setup_dark_theme() {
    echo -e "${BLUE}[THEME] Applying dark theme settings...${NC}"

    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'

    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

    cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintmedium
EOF

    cat > "$HOME/.config/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
EOF

    echo -e "${GREEN}[OK] Dark theme applied for GTK apps.${NC}"
}

fix_kde_menus() {
    echo -e "${BLUE}[FIX] Fixing KDE app associations (Dolphin)...${NC}"

    # Method 1: The Symlink Hack (Most reliable for Arch)
    # Makes 'arch-applications.menu' the default 'applications.menu'
    if [ -f "/etc/xdg/menus/arch-applications.menu" ]; then
        echo -e "${BLUE}[INFO] Symlinking Arch menu to default...${NC}"

        # Backup existing menu if it exists and isn't already a symlink
        if [ -f "/etc/xdg/menus/applications.menu" ] && [ ! -L "/etc/xdg/menus/applications.menu" ]; then
            sudo mv /etc/xdg/menus/applications.menu /etc/xdg/menus/applications.menu.backup
        fi

        # Create the symlink
        sudo ln -sf /etc/xdg/menus/arch-applications.menu /etc/xdg/menus/applications.menu
        echo -e "${GREEN}[OK] Menu symlinked.${NC}"
    fi

    # Method 2: Rebuild Cache (Just in case)
    # Set the variable temporarily for the rebuild process
    export XDG_MENU_PREFIX=arch-

    if command -v kbuildsycoca6 &> /dev/null; then
        kbuildsycoca6 --noincremental &> /dev/null
        echo -e "${GREEN}[OK] KDE Cache (v6) rebuilt.${NC}"
    elif command -v kbuildsycoca5 &> /dev/null; then
        kbuildsycoca5 --noincremental &> /dev/null
        echo -e "${GREEN}[OK] KDE Cache (v5) rebuilt.${NC}"
    else
        echo -e "\033[0;31m[WARNING] kbuildsycoca not found.${NC}"
    fi
}

copy_directory() {
    SRC="$REPO_ROOT/$1"
    DEST="$2"

    echo -e "${BLUE}[COPY] Processing Directory: $1...${NC}"

    if [ -d "$SRC" ]; then
        [ ! -d "$DEST" ] && mkdir -p "$DEST"

        cp -rf "$SRC"/. "$DEST"

        echo -e "${GREEN}Copied content from $1 to $DEST${NC}"
    else
        echo -e "\033[0;31m[WARNING] Directory $SRC missing. Skipping.${NC}"
    fi
}

# --- BLOCK 3: Execution ---

# 1. Install
install_dependencies

# 2. Copy Configs (Full Directories)
echo -e "${BLUE}[COPY] Copying configuration directories...${NC}"

# Hyprland configs
copy_directory ".config/hypr" "$HOME/.config/hypr"

# Kitty configs (includes kitty.conf and themes)
copy_directory ".config/kitty" "$HOME/.config/kitty"

# Wlogout configs (includes layout and icons)
copy_directory ".config/wlogout" "$HOME/.config/wlogout"

# Waybar configs (includes config, style.css, scripts, assets, themes)
copy_directory ".config/waybar" "$HOME/.config/waybar"

# Wofi configs (includes config and css)
copy_directory ".config/wofi" "$HOME/.config/wofi"


# 3. Post-Processing
echo -e "${BLUE}[EXEC] Setting permissions...${NC}"
# Робимо всі скрипти в Waybar та Hyprland виконуваними (рекурсивно)
[ -d "$HOME/.config/waybar" ] && find "$HOME/.config/waybar" -name "*.sh" -exec chmod +x {} \;
[ -d "$HOME/.config/hypr" ] && find "$HOME/.config/hypr" -name "*.sh" -exec chmod +x {} \;

setup_dark_theme
fix_kde_menus

echo -e "${BLUE}[EXEC] Updating font cache...${NC}"
fc-cache -f -v > /dev/null 2>&1

echo -e "${BLUE}[EXEC] Generating Pywal colors...${NC}"
WALLPAPER="$HOME/.config/hypr/wallpapers/wall2.png"
if [ -f "$WALLPAPER" ]; then
    # -n: skip setting wallpaper (just generate colors)
    wal -i "$WALLPAPER" -n > /dev/null
    echo -e "${GREEN}Palette generated!${NC}"
else
    echo -e "\033[0;31m[ERROR] Wallpaper not found at $WALLPAPER.${NC}"
fi

echo -e "${BLUE}[SYSTEM] Enabling services...${NC}"
! systemctl is-enabled sddm &> /dev/null && sudo systemctl enable sddm
! systemctl is-enabled NetworkManager &> /dev/null && sudo systemctl enable NetworkManager && sudo systemctl start NetworkManager
! systemctl is-enabled bluetooth &> /dev/null && sudo systemctl enable bluetooth && sudo systemctl start bluetooth

echo -e "${GREEN}[DONE] Setup complete. Reboot recommended!${NC}"
