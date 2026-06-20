#!/bin/bash

# Complete i3wm Installation Script - Final Optimized Version
# Tested on Debian 12 / Ubuntu 22.04+

set -e          # Exit immediately if a command exits with a non-zero status
set -u          # Treat unset variables as an error when substituting
set -o pipefail # The return value of a pipeline is the status of the last command to exit with a non-zero status

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verify that the script is executed from the correct directory
if [ ! -d ".config" ]; then
    echo_error ".config directory not found in the current working directory"
    echo_error "Make sure to run this script from the directory containing your config files"
    exit 1
fi

echo_info "Updating system package lists and upgrading packages..."
sudo apt-get update && sudo apt-get upgrade -y

echo_info "Installing core utilities and Python package management tools..."
sudo apt-get install -y wget curl git thunar unzip fontconfig pipx

echo_info "Installing the i3 window manager environment..."
sudo apt-get install -y arandr flameshot arc-theme feh i3blocks i3status \
    i3-wm lxappearance rofi unclutter papirus-icon-theme \
    imagemagick picom

# Inject pipx into the PATH for the current shell session
pipx ensurepath
export PATH="$PATH:$HOME/.local/bin"

# Install pywal via pipx (clean and isolated from system packages)
echo_info "Installing pywal..."
pipx install pywal || echo_warn "pywal is already installed"


# Install Sublime Text
echo_info "Installing Sublime Text..."
sudo mkdir -p /etc/apt/keyrings
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null
echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' | sudo tee /etc/apt/sources.list.d/sublime-text.sources > /dev/null
sudo apt-get update
sudo apt-get install -y sublime-text

# Create the local fonts directory
mkdir -p ~/.local/share/fonts/

# Install Nerd Fonts (Latest stable version)
echo_info "Installing Nerd Fonts..."
NERD_FONT_VERSION="v3.2.1"
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/Iosevka.zip
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/RobotoMono.zip
unzip -qo Iosevka.zip -d ~/.local/share/fonts/
unzip -qo RobotoMono.zip -d ~/.local/share/fonts/
rm Iosevka.zip RobotoMono.zip
fc-cache -fv

# Install Alacritty
echo_info "Installing Alacritty..."
if ! command -v alacritty &> /dev/null; then
    echo_info "Attempting installation via apt (fast and recommended)..."
    if sudo apt-get install -y alacritty; then
        echo_info "Alacritty successfully installed via apt"
    else
        # Fallback if absent from repositories (e.g., Ubuntu 22.04) -> Compile from source via cargo
        echo_warn "Alacritty unavailable via apt, compiling from source..."
        sudo apt-get install -y cmake g++ pkg-config libfontconfig1-dev \
            libxcb-xfixes0-dev libxkbcommon-dev python3

        if ! command -v cargo &> /dev/null; then
            echo_info "Installing Rust toolchain (rustup)..."
            curl https://sh.rustup.rs -sSf | sh -s -- -y
            source "$HOME/.cargo/env"
        fi

        cargo install alacritty
    fi
else
    echo_info "Alacritty is already installed"
fi

# Create configuration directories
echo_info "Creating configuration directory structure..."
mkdir -p ~/.config/i3
mkdir -p ~/.config/rofi
mkdir -p ~/.config/alacritty
mkdir -p ~/.config/picom
mkdir -p ~/.config/i3blocks

# Deploy configuration files
echo_info "Copying configuration files..."

# ─── i3 Window Manager ────────────────────────────────────
cp .config/i3/config ~/.config/i3/config                        # Main i3 configuration
cp .config/i3/wallpaper.sh ~/.config/i3/wallpaper.sh           # Wallpaper helper script
chmod +x ~/.config/i3/wallpaper.sh                             # Make executable

# ─── i3blocks (status bar) ────────────────────────────────
cp .config/i3blocks/i3blocks.conf ~/.config/i3blocks/i3blocks.conf

# ─── Alacritty (terminal) ─────────────────────────────────
cp .config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml

# ─── Rofi (app launcher) ──────────────────────────────────
cp .config/rofi/config.rasi ~/.config/rofi/config.rasi

# ─── Picom (compositor) ───────────────────────────────────
cp .config/picom/picom.conf ~/.config/picom/picom.conf

# Copy wallpapers
if [ -d ".wallpaper" ]; then
    cp -r .wallpaper ~/.wallpaper
    echo_info "Wallpapers successfully copied to ~/.wallpaper"
fi

echo ""
echo_info "═══════════════════════════════════════════════════════════"
echo_info "Base environment installation completed successfully!"
echo_info "═══════════════════════════════════════════════════════════"
echo ""
echo_info "Next Steps:"
echo "  1. Choose a wallpaper and run: wal -i /path/to/image"
echo "  2. Edit ~/.fehbg to set the wallpaper on startup"
echo "  3. Reboot your system"
echo "  4. Select 'i3' at your display manager login screen"
echo "  5. Launch 'lxappearance' and select 'Arc-Dark'"
echo ""

# Optional Oh-My-Zsh Installation
read -p "Do you want to install Oh-My-Zsh? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo_info "Installing Zsh..."
    sudo apt-get install -y zsh

    echo_info "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Set Zsh as the default shell
    if [ -f /usr/bin/zsh ]; then
        echo_info "Setting Zsh as the default shell..."
        chsh -s "$(which zsh)"
        echo_warn "You will need to log out and log back in for the shell change to take effect."
    fi
else
    echo_info "Oh-My-Zsh installation skipped"
fi

echo ""
echo_info "Setup complete! Enjoy your new custom i3wm environment!"
