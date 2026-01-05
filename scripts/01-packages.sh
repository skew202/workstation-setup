Manjaro Bootstrap - Package installation script. Installs all pacman and AUR packages in logical order.

#!/bin/bash
################################################################################
# Manjaro Bootstrap - Package Installation
# Author: skew202
# Description: Installs all packages (pacman + AUR) from saved list
#
# This script installs packages in categories for better organization
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

################################################################################
# PACKAGE LISTS
################################################################################

# Core system packages
CORE_PACKAGES=(
    "base"
    "base-devel"
    "linux61"
    "linux612"
    "amd-ucode"
    "grub"
    "grub-btrfs"
    "btrfs-progs"
    "cryptsetup"
    "lvm2"
    "dmraid"
    "mdadm"
    "xfsprogs"
    "jfsutils"
    "reiserfsprogs"
    "f2fs-tools"
    "dosfstools"
    "e2fsprogs"
    "exfatprogs"
    "ntfs-3g"
)

# Development tools
DEV_PACKAGES=(
    "git"
    "git-lfs"
    "github-cli"
    "docker"
    "docker-compose"
    "kubectl"
    "k9s"
    "doctl"
    "kubectl"
    "python-pip"
    "python-pipx"
    "pyenv"
    "rbenv"
    "ruby-build"
    "ruby-bundler"
    "nvm"
    "npm"
    "pnpm"
    "yarn"
    "rust"
    "go"
    "jq"
    "hadolint-bin"
    "trivy"
)

# Security tools (Red/Blue team)
SECURITY_PACKAGES=(
    "nmap"
    "android-sdk-platform-tools"
    "apparmor"
    "lynis"
    "rkhunter"
    "chkrootkit"
    "clamav"
    "aide"
    "ettercap"
    "wireshark-qt"
    "wireshark-cli"
    "tcpdump"
    "john"
    "hashcat"
    "hydra"
    "sqlmap"
    "nikto"
    "gobuster"
    "ffuf"
    "trufflehog"
    "gitleaks"
    "nordvpn-bin"
)

# System monitoring
MONITORING_PACKAGES=(
    "btop"
    "htop"
    "iotop"
    "iftop"
    "nethogs"
    "bandwhich"
    "nvtop"
    "speedtest-cli"
    "tree"
    "baobab"
)

# VPN and network
NETWORK_PACKAGES=(
    "networkmanager"
    "networkmanager-openvpn"
    "networkmanager-openconnect"
    "networkmanager-pptp"
    "networkmanager-vpnc"
    "networkmanager-strongswan"
    "wpa_supplicant"
    "bluez-utils"
    "cloudflared"
)

# Backup and sync
BACKUP_PACKAGES=(
    "timeshift"
    "timeshift-autosnap-manjaro"
    "deja-dup"
    "rsync"
)

# GNOME desktop (adjust if using different DE)
GNOME_PACKAGES=(
    "gdm"
    "gnome-shell"
    "gnome-shell-extensions"
    "gnome-terminal"
    "nautilus"
    "gnome-tweaks"
    "gnome-control-center"
    "gnome-system-monitor"
)

# GNOME extensions
GNOME_EXTENSIONS=(
    "gnome-shell-extension-appindicator"
    "gnome-shell-extension-dash-to-dock"
    "gnome-shell-extension-dash-to-panel"
    "gnome-shell-extension-forge"
    "gnome-shell-extension-gsconnect"
)

# Productivity apps
PRODUCTIVITY_PACKAGES=(
    "firefox"
    "brave-browser"
    "google-chrome"
    "visual-studio-code-bin"
    "zed"
    "libreoffice-still"
    "thunderbird"
    "evince"
    "okular"
    "calibre"
)

# Multimedia
MULTIMEDIA_PACKAGES=(
    "lollypop"
    "totem"
    "vlc"
    "easyeffects"
    "rhythmbox"
)

# NVIDIA drivers (if applicable)
NVIDIA_PACKAGES=(
    "nvidia-utils"
    "nvidia-settings"
    "lib32-nvidia-utils"
    "nvidia-prime"
)

# Container/VM tools
CONTAINER_PACKAGES=(
    "gnome-boxes"
    "distrobox"
    "podman"
)

# AI/ML tools
AI_PACKAGES=(
    "ollama-cuda"
    "python-pytorch-cuda"
    "cuda"
    "cudnn"
)

# Database tools
DATABASE_PACKAGES=(
    "postgresql"
    "postgresql-libs"
    "sqlitebrowser"
)

# TeX/LaTeX
LATEX_PACKAGES=(
    "texlive-basic"
    "texlive-bibtexextra"
    "texlive-fontsextra"
    "texlive-latexextra"
    "texlive-mathscience"
    "texlive-publishers"
    "pandoc-cli"
)

# Other utilities
UTILITY_PACKAGES=(
    "ffmpegthumbnailer"
    "file-roller"
    "gnome-disk-utility"
    "gparted"
    "baobab"
    "simple-scan"
    "seahorse"
    "tmux"
    "zola"
    "yt-dlp"
)

# AUR packages (install with yay)
AUR_PACKAGES=(
    "1password"
    "1password-cli"
    "cursor-bin"
    "slack-bin"
    "supabase"
    "lenovolegionlinux-git"
    "antigravity-bin"
    "gnome-shell-extension-x11gestures"
)

################################################################################
# INSTALLATION FUNCTIONS
################################################################################

install_pacman_packages() {
    local category="$1"
    shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        return
    fi

    log_info "Installing $category..."

    # Filter out already installed packages
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        sudo pacman -S --noconfirm "${to_install[@]}" || log_warn "Some packages failed to install"
        log_success "$category installed"
    else
        log_info "$category already installed"
    fi
}

install_aur_packages() {
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        return
    fi

    # Ensure yay is installed
    if ! command -v yay &>/dev/null; then
        log_info "Installing yay..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    fi

    log_info "Installing AUR packages..."

    # Filter out already installed packages
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        yay -S --noconfirm "${to_install[@]}" || log_warn "Some AUR packages failed to install"
        log_success "AUR packages installed"
    else
        log_info "AUR packages already installed"
    fi
}

install_from_list() {
    local list_file="$1"

    if [[ ! -f "$list_file" ]]; then
        log_warn "Package list not found: $list_file"
        return 1
    fi

    log_info "Installing packages from $list_file..."

    while read -r pkg; do
        # Skip comments and empty lines
        [[ "$pkg" =~ ^#.*$ ]] && continue
        [[ -z "$pkg" ]] && continue

        if ! pacman -Q "$pkg" &>/dev/null; then
            log_info "Installing $pkg..."
            sudo pacman -S --noconfirm "$pkg" || log_warn "Failed to install $pkg"
        fi
    done < "$list_file"
}

################################################################################
# INTERACTIVE INSTALLATION
################################################################################

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Package Installation Script                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

    # Check if packages.txt exists and use that instead
    if [[ -f "packages.txt" ]]; then
        log_info "Found packages.txt. Installing from list..."
        install_from_list "packages.txt"
        return 0
    fi

    # Otherwise, install by category
    local install_all=false
    if [[ "${1:-}" == "--all" ]]; then
        install_all=true
    fi

    # Core
    install_pacman_packages "Core System" "${CORE_PACKAGES[@]}"

    # Development
    if [[ "$install_all" == true ]] || confirm "Install development tools?"; then
        install_pacman_packages "Development Tools" "${DEV_PACKAGES[@]}"
    fi

    # Security
    if [[ "$install_all" == true ]] || confirm "Install security tools?"; then
        install_pacman_packages "Security Tools" "${SECURITY_PACKAGES[@]}"
    fi

    # Monitoring
    install_pacman_packages "Monitoring" "${MONITORING_PACKAGES[@]}"

    # Network
    install_pacman_packages "Network & VPN" "${NETWORK_PACKAGES[@]}"

    # Backup
    install_pacman_packages "Backup" "${BACKUP_PACKAGES[@]}"

    # GNOME (check if running GNOME)
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || [[ "$install_all" == true ]]; then
        install_pacman_packages "GNOME Desktop" "${GNOME_PACKAGES[@]}"
        install_pacman_packages "GNOME Extensions" "${GNOME_EXTENSIONS[@]}"
    fi

    # Productivity
    if [[ "$install_all" == true ]] || confirm "Install productivity apps?"; then
        install_pacman_packages "Productivity" "${PRODUCTIVITY_PACKAGES[@]}"
    fi

    # Multimedia
    install_pacman_packages "Multimedia" "${MULTIMEDIA_PACKAGES[@]}"

    # NVIDIA (only if NVIDIA GPU detected)
    if lspci | grep -qi "nvidia"; then
        install_pacman_packages "NVIDIA Drivers" "${NVIDIA_PACKAGES[@]}"
    fi

    # Containers
    if [[ "$install_all" == true ]] || confirm "Install container/VM tools?"; then
        install_pacman_packages "Containers" "${CONTAINER_PACKAGES[@]}"
    fi

    # AI/ML
    if [[ "$install_all" == true ]] || confirm "Install AI/ML tools?"; then
        install_pacman_packages "AI/ML" "${AI_PACKAGES[@]}"
    fi

    # Database
    if [[ "$install_all" == true ]] || confirm "Install database tools?"; then
        install_pacman_packages "Database" "${DATABASE_PACKAGES[@]}"
    fi

    # LaTeX
    if [[ "$install_all" == true ]] || confirm "Install LaTeX?"; then
        install_pacman_packages "LaTeX" "${LATEX_PACKAGES[@]}"
    fi

    # Utilities
    install_pacman_packages "Utilities" "${UTILITY_PACKAGES[@]}"

    # AUR packages
    if [[ "$install_all" == true ]] || confirm "Install AUR packages?"; then
        install_aur_packages "${AUR_PACKAGES[@]}"
    fi

    echo ""
    log_success "Package installation complete!"
    log_info "You may want to reboot to ensure all changes take effect."
}

confirm() {
    local prompt="$1"
    read -r -p "$prompt [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

main "$@"
