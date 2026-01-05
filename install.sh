Manjaro Bootstrap - Main entry point script. Orchestrates full system restoration on fresh Manjaro install.

#!/bin/bash
################################################################################
# Manjaro Bootstrap Script - Main Entry Point
# Author: skew202
# Description: Orchestrates full system restoration on fresh Manjaro install
# Usage: curl -sL <gist-url>/bootstrap.sh | bash
#
# Order of operations:
#   1. Update system
#   2. Install packages (01-packages.sh)
#   3. Configure services (02-services.sh)
#   4. Apply hardening (03-hardening.sh)
#   5. Install custom scripts (04-scripts.sh)
################################################################################

set -euo pipefail

################################################################################
# CONFIGURATION
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script locations (can be overridden with env vars)
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/.bootstrap}"
SCRIPTS_BASE_URL="${SCRIPTS_BASE_URL:-https://gist.githubusercontent.com/skew202}"

# Gist IDs (update these after creating the gists)
GIST_PACKAGES="${GIST_PACKAGES:-}"
GIST_SERVICES="${GIST_SERVICES:-}"
GIST_HARDENING="${GIST_HARDENING:-}"
GIST_SCRIPTS="${GIST_SCRIPTS:-}"

################################################################################
# UTILITIES
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}═══ $1 ═══${NC}"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should NOT be run as root"
        log_info "Run as your normal user. sudo will be used when needed."
        exit 1
    fi
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]"
    else
        prompt="$prompt [y/N]"
    fi

    while true; do
        read -r -p "$prompt " response
        case "$response" in
            [Yy][Ee][Ss]|[Yy])
                return 0
                ;;
            [Nn][Oo]|[Nn])
                return 1
                ;;
            "")
                if [[ "$default" == "y" ]]; then
                    return 0
                else
                    return 1
                fi
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

################################################################################
# SYSTEM CHECKS
################################################################################

check_manjaro() {
    if [[ ! -f /etc/manjaro-release ]]; then
        log_error "This script is designed for Manjaro Linux"
        log_info "It may work on Arch, but proceed with caution."
        confirm "Continue anyway?" "n" || exit 1
    fi
}

check_internet() {
    if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
        log_error "No internet connection detected"
        log_info "Please connect to the internet before running this script."
        exit 1
    fi
}

check_pacman() {
    if ! pgrep -x "pacman" &>/dev/null; then
        log_info "Checking for pacman locks..."
        sudo rm -f /var/lib/pacman/db.lck || true
    fi
}

################################################################################
# SCRIPT DOWNLOADERS
################################################################################

download_script() {
    local name="$1"
    local url="$2"
    local dest="$BOOTSTRAP_DIR/${name}.sh"

    mkdir -p "$BOOTSTRAP_DIR"

    if [[ -f "$dest" ]]; then
        log_info "Script $name already exists. Updating..."
    fi

    log_info "Downloading $name..."
    if curl -fsSL "$url" -o "$dest"; then
        chmod +x "$dest"
        log_success "Downloaded $name"
        echo "$dest"
    else
        log_error "Failed to download $name"
        return 1
    fi
}

################################################################################
# INSTALLATION STEPS
################################################################################

update_system() {
    log_step "Updating System"

    log_info "Updating package databases..."
    sudo pacman -Sy --noconfirm

    log_info "Upgrading system packages..."
    sudo pacman -Syu --noconfirm

    log_success "System updated"
}

install_base_tools() {
    log_step "Installing Base Tools"

    local tools=(
        "base-devel"
        "git"
        "curl"
        "wget"
        "jq"
        "tree"
        "bat"
        "ripgrep"
        "fd"
    )

    for tool in "${tools[@]}"; do
        if ! pacman -Q "$tool" &>/dev/null; then
            log_info "Installing $tool..."
            sudo pacman -S --noconfirm "$tool" || log_warn "Failed to install $tool"
        fi
    done

    # Install yay if not present
    if ! command -v yay &>/dev/null; then
        log_info "Installing yay (AUR helper)..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    fi

    log_success "Base tools installed"
}

run_packages_script() {
    log_step "Installing Packages"

    local script_path
    if [[ -n "$GIST_PACKAGES" ]]; then
        script_path=$(download_script "01-packages" \
            "https://gist.githubusercontent.com/skew202/$GIST_PACKAGES/raw/packages.sh")
    else
        script_path="$BOOTSTRAP_DIR/01-packages.sh"
        if [[ ! -f "$script_path" ]]; then
            log_warn "01-packages.sh not found. Skipping package installation."
            log_info "Run this script after setting GIST_PACKAGES environment variable."
            return 0
        fi
    fi

    "$script_path"
}

run_services_script() {
    log_step "Configuring Services"

    local script_path
    if [[ -n "$GIST_SERVICES" ]]; then
        script_path=$(download_script "02-services" \
            "https://gist.githubusercontent.com/skew202/$GIST_SERVICES/raw/services.sh")
    else
        script_path="$BOOTSTRAP_DIR/02-services.sh"
        if [[ ! -f "$script_path" ]]; then
            log_warn "02-services.sh not found. Skipping service configuration."
            return 0
        fi
    fi

    "$script_path"
}

run_hardening_script() {
    log_step "Applying Security Hardening"

    local script_path
    if [[ -n "$GIST_HARDENING" ]]; then
        script_path=$(download_script "03-hardening" \
            "https://gist.githubusercontent.com/skew202/$GIST_HARDENING/raw/hardening.sh")
    else
        script_path="$BOOTSTRAP_DIR/03-hardening.sh"
        if [[ ! -f "$script_path" ]]; then
            log_warn "03-hardening.sh not found. Skipping hardening."
            return 0
        fi
    fi

    "$script_path"
}

run_scripts_installer() {
    log_step "Installing Custom Scripts"

    local script_path
    if [[ -n "$GIST_SCRIPTS" ]]; then
        script_path=$(download_script "04-scripts" \
            "https://gist.githubusercontent.com/skew202/$GIST_SCRIPTS/raw/scripts.sh")
    else
        script_path="$BOOTSTRAP_DIR/04-scripts.sh"
        if [[ ! -f "$script_path" ]]; then
            log_warn "04-scripts.sh not found. Skipping custom scripts installation."
            return 0
        fi
    fi

    "$script_path"
}

################################################################################
# MAIN
################################################################################

print_banner() {
    cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   ____  _____ ___  ____  ___ ___ ____    _    _  _        ║
║  |  _ \| ____/ _ \|  _ \|_ _|_ _/ ___|  / \  | \| |       ║
║  | |_) |  _|| | | | | | | | | | \___ \ / _ \ | .` |       ║
║  |  _ <| |__| |_| | |_| | | | |  |) / / ___ \| |\ |       ║
║  |_| \_\_____\___/|____/___|___|____/_/_/   \_\_| \_|      ║
║                                                            ║
║            Manjaro System Bootstrap Script                ║
║                                                            ║
║  Author: skew202                                           ║
║  Source: https://github.com/skew202                        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
}

main() {
    print_banner

    # Pre-flight checks
    check_root
    check_manjaro
    check_internet
    check_pacman

    log_info "Bootstrap directory: $BOOTSTRAP_DIR"
    mkdir -p "$BOOTSTRAP_DIR"

    # Ask what to install
    log_step "Select Installation Steps"

    DO_UPDATE=true
    DO_BASE=true
    DO_PACKAGES=$(confirm "Install all packages?" "y" && echo true || echo false)
    DO_SERVICES=$(confirm "Configure services?" "y" && echo true || echo false)
    DO_HARDENING=$(confirm "Apply security hardening?" "y" && echo true || echo false)
    DO_SCRIPTS=$(confirm "Install custom scripts?" "y" && echo true || echo false)

    # Run selected steps
    [[ "$DO_UPDATE" == true ]] && update_system
    [[ "$DO_BASE" == true ]] && install_base_tools
    [[ "$DO_PACKAGES" == true ]] && run_packages_script
    [[ "$DO_SERVICES" == true ]] && run_services_script
    [[ "$DO_HARDENING" == true ]] && run_hardening_script
    [[ "$DO_SCRIPTS" == true ]] && run_scripts_installer

    # Done
    log_step "Bootstrap Complete!"

    log_info "Next steps:"
    echo "  1. Reboot your system (required for kernel changes)"
    echo "  2. Run Lynis audit: sudo lynis audit system"
    echo "  3. Configure NordVPN: nordvpn-helper nordlynx"
    echo "  4. Restore dotfiles from backup (if applicable)"

    # Offer reboot
    if confirm "Reboot now?" "n"; then
        sudo reboot
    fi
}

main "$@"
