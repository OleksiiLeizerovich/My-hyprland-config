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

# Ця функція тепер копіює вміст папки рекурсивно
copy_directory() {
    SRC="$REPO_ROOT/$1"
    DEST="$2"

    echo -e "${BLUE}[COPY] Processing Directory: $1...${NC}"

    if [ -d "$SRC" ]; then
        [ ! -d "$DEST" ] && mkdir -p "$DEST"

        # Використовуємо /. щоб скопіювати ВМІСТ папки (включно з прихованими файлами)
        # Прапорці: -r (рекурсивно), -f (форсувати перезапис)
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
