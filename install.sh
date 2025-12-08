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
    "ttf-source-code-pro-nerd"
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

copy_config_file() {
    SRC="$REPO_ROOT/$1"; DEST="$2"; DEST_DIR=$(dirname "$DEST")
    echo -e "${BLUE}[COPY] Processing $1...${NC}"
    if [ -f "$SRC" ]; then
        [ ! -d "$DEST_DIR" ] && mkdir -p "$DEST_DIR"
        if [ -f "$DEST" ] && ! cmp -s "$SRC" "$DEST"; then mv "$DEST" "$DEST.backup.$(date +%s)"; cp "$SRC" "$DEST"; echo -e "${GREEN}Updated!${NC}";
        elif [ ! -f "$DEST" ]; then cp "$SRC" "$DEST"; echo -e "${GREEN}Copied!${NC}"; else echo "Skipping identical file."; fi
    else echo "Warning: File $SRC missing."; fi
}

copy_directory() {
    SRC="$REPO_ROOT/$1"; DEST="$2"
    echo -e "${BLUE}[COPY] Directory $1...${NC}"
    if [ -d "$SRC" ]; then
        [ ! -d "$DEST" ] && mkdir -p "$DEST"
        cp -r "$SRC"/* "$DEST"
        echo -e "${GREEN}Copied recursively!${NC}"
    else echo "Warning: Directory $SRC missing."; fi
}

# --- BLOCK 3: Execution ---

# 1. Install
install_dependencies

# 2. Copy Configs
copy_directory ".config/hypr" "$HOME/.config/hypr"
copy_config_file ".config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
copy_config_file ".config/kitty/GruvBox_DarkHard.conf" "$HOME/.config/kitty/GruvBox_DarkHard.conf"
copy_config_file ".config/wlogout/layout" "$HOME/.config/wlogout/layout"
copy_config_file ".config/waybar/config" "$HOME/.config/waybar/config"
copy_config_file ".config/waybar/style.css" "$HOME/.config/waybar/style.css"
copy_directory ".config/waybar/scripts" "$HOME/.config/waybar/scripts"
copy_directory ".config/waybar/assets" "$HOME/.config/waybar/assets"
copy_directory ".config/waybar/themes" "$HOME/.config/waybar/themes"
copy_config_file ".config/wofi/config" "$HOME/.config/wofi/config"
copy_config_file ".config/wofi/menu.css" "$HOME/.config/wofi/menu.css"

# 3. Post-Processing
echo -e "${BLUE}[EXEC] Setting permissions...${NC}"
[ -d "$HOME/.config/waybar/scripts" ] && chmod +x "$HOME/.config/waybar/scripts/"*.sh
[ -d "$HOME/.config/hypr" ] && find "$HOME/.config/hypr" -name "*.sh" -exec chmod +x {} \;

echo -e "${BLUE}[EXEC] Updating font cache...${NC}"
fc-cache -f -v > /dev/null 2>&1

echo -e "${BLUE}[EXEC] Generating Pywal colors...${NC}"
WALLPAPER="$HOME/.config/hypr/wallpapers/wall2.png"
if [ -f "$WALLPAPER" ]; then
    wal -i "$WALLPAPER" -n > /dev/null
    echo -e "${GREEN}Palette generated!${NC}"
else
    echo -e "\033[0;31m[ERROR] Wallpaper not found at $WALLPAPER.${NC}"
fi

echo -e "${BLUE}[SYSTEM] Enabling services...${NC}"
! systemctl is-enabled sddm &> /dev/null && sudo systemctl enable sddm
! systemctl is-enabled NetworkManager &> /dev/null && sudo systemctl enable NetworkManager && sudo systemctl start NetworkManager
! systemctl is-enabled bluetooth &> /dev/null && sudo systemctl enable bluetooth && sudo systemctl start bluetooth

echo -e "${GREEN}[DONE] Reboot recommended!${NC}"
