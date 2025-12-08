#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Path to the repository root (where this script is located)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}[INFO] Starting Hyprland setup...${NC}"

# --- BLOCK 1: Variables ---

# List of dependencies (pacman/aur packages)
DEPENDENCIES=(
    "hyprland"
    "git"
    "kitty"             # Terminal
    "dolphin"           # File Manager
    "wofi"              # Application Launcher
    "waybar"            # Status Bar
    "wlogout"           # Logout Menu
    "swww"              # Wallpaper Daemon
    "waypaper"          # Wallpaper Manager GUI
    "kdeconnect"        # Phone integration
    "polkit-gnome"      # Authentication Agent
    "swaync"            # Notification Center
    "gammastep"         # Blue light filter
    "hypridle"          # Idle daemon
    "hyprlock"          # Lock screen
    "wl-clipboard"      # Clipboard utilities
    "cliphist"          # Clipboard history
    "grim"              # Screenshot tool
    "slurp"             # Region selector for screenshots
    "satty"             # Screenshot editor
    "jq"                # JSON processor
    "btop"              # System monitor
    "brightnessctl"     # Brightness control
    "playerctl"         # Media player control
    "qt6ct"             # Qt6 configuration tool

    # Waybar specific dependencies
    "pavucontrol"       # Volume control GUI
    "blueman"           # Bluetooth manager GUI
    "networkmanager"    # Network manager (nmtui & nmcli)
    "pacman-contrib"    # 'checkupdates' utility
    "python-pywal"      # Pywal for color generation
    "hyprpicker"        # Color picker
    "imagemagick"       # Image manipulation
    "libnotify"         # Notifications

    # Fonts
    "ttf-nerd-fonts-symbols"     # Icons
    "apple-fonts"                # SF Pro Display (AUR)
    "ttf-source-code-pro-nerd"   # For Kitty (SauceCodePro)
    "ttf-jetbrains-mono-nerd"    # For Waybar (JetBrainsMono)
)

# --- BLOCK 2: Functions ---

install_dependencies() {
    echo -e "${BLUE}[INFO] Installing dependencies...${NC}"

    # Check for AUR helper (yay or paru)
    if command -v yay &> /dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &> /dev/null; then
        AUR_HELPER="paru"
    else
        echo "Error: AUR helper not found (yay or paru). Please install it manually."
        exit 1
    fi

    for PACKAGE in "${DEPENDENCIES[@]}"; do
        if ! pacman -Qi "$PACKAGE" &> /dev/null; then
            echo -e "Installing: $PACKAGE"
            $AUR_HELPER -S --needed --noconfirm "$PACKAGE"
        else
            echo -e "${GREEN}[OK] $PACKAGE is already installed.${NC}"
        fi
    done
}

copy_config_file() {
    # $1 - Relative path in repo (e.g., .config/hypr/hyprland.conf)
    # $2 - Absolute destination path (e.g., $HOME/.config/hypr/hyprland.conf)

    SRC="$REPO_ROOT/$1"
    DEST="$2"
    DEST_DIR=$(dirname "$DEST")

    echo -e "${BLUE}[COPY] Processing $1...${NC}"

    if [ -f "$SRC" ]; then
        if [ ! -d "$DEST_DIR" ]; then
            mkdir -p "$DEST_DIR"
            echo "Created directory: $DEST_DIR"
        fi

        if [ -f "$DEST" ]; then
            if ! cmp -s "$SRC" "$DEST"; then
                mv "$DEST" "$DEST.backup.$(date +%s)"
                echo "Backup created for existing file."
                cp "$SRC" "$DEST"
                echo -e "${GREEN}File updated!${NC}"
            else
                echo "File is identical, skipping."
            fi
        else
            cp "$SRC" "$DEST"
            echo -e "${GREEN}File copied!${NC}"
        fi
    else
        echo "Warning: File $SRC not found in repository (skipping)."
    fi
}

copy_directory() {
    # $1 - Relative path in repo
    # $2 - Absolute destination path
    SRC="$REPO_ROOT/$1"
    DEST="$2"

    echo -e "${BLUE}[COPY] Processing directory $1...${NC}"

    if [ -d "$SRC" ]; then
        if [ ! -d "$DEST" ]; then
            mkdir -p "$DEST"
            echo "Created directory: $DEST"
        fi
        cp -r "$SRC"/* "$DEST"
        echo -e "${GREEN}Directory content copied!${NC}"
    else
        echo "Warning: Directory $SRC not found in repository (skipping)."
    fi
}

# --- BLOCK 3: Execution ---

# 1. Install packages
install_dependencies

# 2. Copy configs

# Hyprland
copy_config_file ".config/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
copy_config_file ".config/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
copy_config_file ".config/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
copy_config_file ".config/hypr/hyprlock.png" "$HOME/.config/hypr/hyprlock.png"
copy_config_file ".config/hypr/vivek.png" "$HOME/.config/hypr/vivek.png"

# Kitty
copy_config_file ".config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
copy_config_file ".config/kitty/GruvBox_DarkHard.conf" "$HOME/.config/kitty/GruvBox_DarkHard.conf"

# Wlogout
copy_config_file ".config/wlogout/layout" "$HOME/.config/wlogout/layout"

# Waybar
copy_config_file ".config/waybar/config" "$HOME/.config/waybar/config"
copy_config_file ".config/waybar/style.css" "$HOME/.config/waybar/style.css"
copy_directory ".config/waybar/scripts" "$HOME/.config/waybar/scripts"
copy_directory ".config/waybar/assets" "$HOME/.config/waybar/assets"
copy_directory ".config/waybar/themes" "$HOME/.config/waybar/themes"

# Wofi
copy_config_file ".config/wofi/config" "$HOME/.config/wofi/config"
copy_config_file ".config/wofi/menu.css" "$HOME/.config/wofi/menu.css"

# Make scripts executable
if [ -d "$HOME/.config/waybar/scripts" ]; then
    echo -e "${BLUE}[EXEC] Making scripts executable...${NC}"
    chmod +x "$HOME/.config/waybar/scripts/"*.sh
fi

echo -e "${GREEN}[DONE] Setup completed!${NC}"
