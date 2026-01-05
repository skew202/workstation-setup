#!/bin/bash
################################################################################
# Manjaro Bootstrap - Package Installation
# Refactored: Reads lists from data/packages/*.txt
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$REPO_ROOT/data/packages"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

install_from_file() {
    local name="$1"
    local file="$2"
    local is_aur="${3:-false}"

    if [[ ! -f "$file" ]]; then
        log_warn "File not found: $file"
        return
    fi
    
    # Read lines into array, skipping empty/comments
    mapfile -t packages < <(grep -vE "^#|^$" "$file")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        return
    fi

    log_info "Installing $name..."
    
    # Filter installed
    local to_install=()
    for pkg in "${packages[@]}"; do
        # Remove carriage returns just in case
        pkg=$(echo "$pkg" | tr -d '\r')
        if ! pacman -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_info "$name already installed"
        return
    fi
    
    if [[ "$is_aur" == "true" ]]; then
        if ! command -v yay &>/dev/null; then
             log_warn "yay not found, skipping AUR packages"
             return
        fi
        yay -S --noconfirm "${to_install[@]}" || log_warn "Failed to install some AUR packages"
    else
        sudo pacman -S --noconfirm "${to_install[@]}" || log_warn "Failed to install some packages"
    fi
    log_success "$name installed"
}

confirm() {
    local prompt="$1"
    read -r -p "$prompt [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

main() {
    echo -e "${BLUE}╔════════ Package Installation ════════╗${NC}"
    
    local install_all=false
    if [[ "${1:-}" == "--all" ]]; then
        install_all=true
    fi

    # Core (Always install)
    install_from_file "Core System" "$DATA_DIR/core.txt"

    # Interactive Sections
    # Map: Description -> Filename
    # Order matters
    
    declare -A SECTIONS=(
        ["Development Tools"]="development.txt"
        ["Security Tools"]="security.txt"
        ["Monitoring"]="monitoring.txt"
        ["Network/VPN"]="network.txt"
        ["Backup"]="backup.txt"
        ["Productivity"]="productivity.txt"
        ["Multimedia"]="multimedia.txt"
        ["Containers"]="containers.txt"
        ["AI/ML Tools"]="ai_ml.txt"
        ["Databases"]="database.txt"
        ["LaTeX"]="latex.txt"
        ["Utilities"]="utilities.txt"
    )
    
    # GNOME Special Case
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || [[ "$install_all" == true ]]; then
        install_from_file "GNOME Desktop" "$DATA_DIR/gnome.txt"
        install_from_file "GNOME Extensions" "$DATA_DIR/gnome_extensions.txt"
    fi
    
    # NVIDIA Special Case
    if lspci | grep -qi "nvidia"; then
        install_from_file "NVIDIA Drivers" "$DATA_DIR/nvidia.txt"
    fi

    # Loop through sections
    # Note: Bash assoc arrays have no order. simpler to just list them.
    
    install_section() {
        local name="$1"
        local file="$DATA_DIR/$2"
        if [[ "$install_all" == true ]] || confirm "Install $name?"; then
            install_from_file "$name" "$file"
        fi
    }

    install_section "Development Tools" "development.txt"
    install_section "Security Tools" "security.txt"
    install_section "Monitoring" "monitoring.txt"
    install_section "Network/VPN" "network.txt"
    install_section "Backup" "backup.txt"
    install_section "Productivity" "productivity.txt"
    install_section "Multimedia" "multimedia.txt"
    install_section "Containers" "containers.txt"
    install_section "AI/ML Tools" "ai_ml.txt"
    install_section "Databases" "database.txt"
    install_section "LaTeX" "latex.txt"
    install_section "Utilities" "utilities.txt"
    
    # AUR
    if [[ "$install_all" == true ]] || confirm "Install AUR packages?"; then
        install_from_file "AUR Packages" "$DATA_DIR/aur.txt" "true"
    fi

    echo ""
    log_success "Installation Complete!"
}

main "$@"
