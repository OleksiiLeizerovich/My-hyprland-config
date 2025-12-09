#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Path to the repository root (where this script is located)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}[INFO] Starting Hyprland setup...${NC}"

# --- BLOCK 1: Variables ---

DEPENDENCIES=(
    # --- Core Hyprland & System ---
    "hyprland"
    "git"
    "sddm"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"

    # --- UI & Theming ---
    "kitty"
    "wofi"
    "waybar"
    "swww"
    "waypaper"
    "swaync"
    "hyprlock"
    "wlogout"
    "hypridle"
    "qt5-wayland" "qt6-wayland" "qt6ct" "nwg-look"

    # Themes for Qt to match GTK Adwaita Dark
    "adwaita-qt5" "adwaita-qt6"

    # --- Utilities ---
    "dolphin"
    "archlinux-xdg-menu"
    "kate"
    "ark"
    "7zip"
    "unrar"

    "kdeconnect"
    "polkit-gnome"
    "gammastep"
    "wl-clipboard"
    "cliphist"
    "grim" "slurp" "satty"
    "jq"
    "btop"
    "brightnessctl"
    "playerctl"
    "bemoji-git"

    # --- Waybar Specific ---
    "pavucontrol" "blueman" "networkmanager" "pacman-contrib"
    "python-pywal"
    "hyprpicker"
    "imagemagick"
    "libnotify"

    # --- Fonts & Icons ---
    "ttf-nerd-fonts-symbols"
    "apple-fonts"
    "ttf-sourcecodepro-nerd"
    "ttf-jetbrains-mono-nerd"
    "noto-fonts"
    "noto-fonts-emoji"
)

# --- BLOCK 2: Functions ---

install_dependencies() {
    echo -e "${BLUE}[INFO] Checking dependencies...${NC}"

    if command -v yay &> /dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &> /dev/null; then
        AUR_HELPER="paru"
    else
        echo -e "${RED}[ERROR] AUR helper (yay or paru) missing. Please install one first.${NC}"
        exit 1
    fi

    MISSING_PKGS=()

    for PACKAGE in "${DEPENDENCIES[@]}"; do
        if ! pacman -Qi "$PACKAGE" &> /dev/null; then
            MISSING_PKGS+=("$PACKAGE")
        fi
    done

    if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
        echo -e "${YELLOW}[INSTALL] Installing missing packages: ${MISSING_PKGS[*]}${NC}"
        # Install all missing packages in one go (Batch Install)
        $AUR_HELPER -S --needed --noconfirm "${MISSING_PKGS[@]}"
    else
        echo -e "${GREEN}[OK] All dependencies are already installed.${NC}"
    fi
}

setup_dark_theme() {
    echo -e "${BLUE}[THEME] Applying dark theme settings...${NC}"

    # GNOME/GTK settings
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'

    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

    # GTK 3
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

    # GTK 4
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

backup_config() {
    DIR_PATH="$1"
    if [ -d "$DIR_PATH" ]; then
        BACKUP_NAME="${DIR_PATH}_backup_$(date +%s)"
        echo -e "${YELLOW}[BACKUP] Found existing config at $DIR_PATH. Moving to $BACKUP_NAME${NC}"
        mv "$DIR_PATH" "$BACKUP_NAME"
    fi
}

copy_directory() {
    SRC="$REPO_ROOT/$1"
    DEST="$2"

    echo -e "${BLUE}[COPY] Processing Directory: $1...${NC}"

    if [ -d "$SRC" ]; then
        # Perform backup before copying
        backup_config "$DEST"

        # Create destination and copy
        mkdir -p "$DEST"
        cp -rf "$SRC"/. "$DEST"

        echo -e "${GREEN}Copied content from $1 to $DEST${NC}"
    else
        echo -e "${RED}[WARNING] Directory $SRC missing in repo. Skipping.${NC}"
    fi
}

setup_dolphin_fix() {
    echo -e "${BLUE}[FIX] Applying Dolphin menu fix (Arch specific)...${NC}"

    # 1. Update desktop database
    sudo update-desktop-database

    # 2. Handle menu renaming
    MENU_DIR="/etc/xdg/menus"
    ARCH_MENU="$MENU_DIR/arch-applications.menu"
    TARGET_MENU="$MENU_DIR/applications.menu"

    if [ -f "$ARCH_MENU" ]; then
        # Backup existing applications.menu if it's not the one we want
        if [ -f "$TARGET_MENU" ]; then
            echo -e "${YELLOW}Backing up existing applications.menu...${NC}"
            sudo mv "$TARGET_MENU" "${TARGET_MENU}.bak.$(date +%s)"
        fi

        echo -e "Copying arch-applications.menu to applications.menu..."
        # We use CP instead of MV to keep the original file safe for pacman updates
        sudo cp "$ARCH_MENU" "$TARGET_MENU"
    else
        echo -e "${RED}[ERROR] $ARCH_MENU not found! Is archlinux-xdg-menu installed?${NC}"
    fi

    # 3. Rebuild Sycoca cache
    echo -e "Rebuilding KDE configuration cache..."
    kbuildsycoca6 --noincremental

    echo -e "${GREEN}[OK] Dolphin fix applied.${NC}"
}

# --- BLOCK 3: Execution ---

# 1. Install
install_dependencies

# 2. Copy Configs (Full Directories with Backup)
echo -e "${BLUE}[COPY] Copying configuration directories...${NC}"

# Define folders to copy
declare -A CONFIG_MAP=(
    [".config/hypr"]="$HOME/.config/hypr"
    [".config/kitty"]="$HOME/.config/kitty"
    [".config/wlogout"]="$HOME/.config/wlogout"
    [".config/waybar"]="$HOME/.config/waybar"
    [".config/wofi"]="$HOME/.config/wofi"
)

for SRC in "${!CONFIG_MAP[@]}"; do
    copy_directory "$SRC" "${CONFIG_MAP[$SRC]}"
done

# 3. Post-Processing
echo -e "${BLUE}[EXEC] Setting permissions...${NC}"
# Make scripts executable
[ -d "$HOME/.config/waybar" ] && find "$HOME/.config/waybar" -name "*.sh" -exec chmod +x {} \;
[ -d "$HOME/.config/hypr" ] && find "$HOME/.config/hypr" -name "*.sh" -exec chmod +x {} \;

# Applying GTK Dark Theme
setup_dark_theme

# Apply Dolphin Fix
setup_dolphin_fix

echo -e "${BLUE}[EXEC] Updating font cache...${NC}"
fc-cache -f -v > /dev/null 2>&1

echo -e "${BLUE}[EXEC] Initializing Wallpaper Daemon & Generating Colors...${NC}"
# Initialize swww if not running, so wal can work if it relies on backend
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon --format xrgb &
    sleep 1 # Wait for daemon to start
fi

WALLPAPER="$HOME/.config/hypr/wallpapers/wall2.png"

if [ -f "$WALLPAPER" ]; then
    echo -e "Setting wallpaper: $WALLPAPER"
    swww img "$WALLPAPER" --transition-type grow --transition-pos 0.854,0.977 --transition-step 90

    # Generate Pywal colors
    wal -i "$WALLPAPER" -n > /dev/null

    # Optional: Fix pywal templates for waybar if you use them
    # cp "$HOME/.cache/wal/colors-waybar.css" "$HOME/.config/waybar/colors.css" 2>/dev/null || true

    echo -e "${GREEN}Palette generated & Wallpaper set!${NC}"
else
    echo -e "${RED}[ERROR] Wallpaper not found at $WALLPAPER.${NC}"
fi

echo -e "${BLUE}[SYSTEM] Enabling services...${NC}"
! systemctl is-enabled sddm &> /dev/null && sudo systemctl enable sddm
! systemctl is-enabled NetworkManager &> /dev/null && sudo systemctl enable NetworkManager && sudo systemctl start NetworkManager
! systemctl is-enabled bluetooth &> /dev/null && sudo systemctl enable bluetooth && sudo systemctl start bluetooth

# Clean up
echo -e "${GREEN}[DONE] Setup complete. Please reboot your system!${NC}"
