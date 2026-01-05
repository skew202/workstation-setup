Manjaro Bootstrap - Services configuration script. Enables and configures systemd services (Docker, NordVPN, UFW, AppArmor, etc.).

#!/bin/bash
################################################################################
# Manjaro Bootstrap - Services Configuration
# Author: skew202
# Description: Enables and configures systemd services
#
# Order: Run AFTER package installation
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
# SERVICE LIST
################################################################################

# Services to enable
SERVICES=(
    # Security
    "apparmor.service"
    "auditd.service"
    "ufw.service"

    # VPN
    "nordvpnd.service"

    # Container
    "docker.service"
    "containerd.service"

    # System
    "systemd-timesyncd.service"
    "fstrim.timer"

    # BTRFS maintenance (if using BTRFS)
    "btrfs-balance.timer"
    "btrfs-scrub.timer"
    "btrfs-trim.timer"
)

# Services to disable (for security/performance)
DISABLE_SERVICES=(
    # Disable if not using printers
    # "cups.service"
    # "cups-browsed.service"

    # Disable if not using Bluetooth
    # "bluetooth.service"
)

################################################################################
# CONFIGURATION
################################################################################

configure_docker() {
    if ! command -v docker &>/dev/null; then
        return
    fi

    log_info "Configuring Docker..."

    # Add user to docker group
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        log_success "Added $USER to docker group"
        log_warn "You need to log out and back in for this to take effect"
    fi

    # Enable docker service
    sudo systemctl enable docker.service
    sudo systemctl start docker.service

    log_success "Docker configured"
}

configure_nordvpn() {
    if ! command -v nordvpn &>/dev/null; then
        return
    fi

    log_info "Configuring NordVPN..."

    # Enable service
    sudo systemctl enable nordvpnd.service
    sudo systemctl start nordvpnd.service

    log_success "NordVPN service enabled"
    log_info "Run 'nordvpn-helper nordlynx' after login to configure"
}

configure_ufw() {
    if ! command -v ufw &>/dev/null; then
        return
    fi

    log_info "Configuring UFW firewall..."

    # Set default policies
    sudo ufw default allow outgoing
    sudo ufw default deny incoming

    # Allow local network (adjust subnet as needed)
    # sudo ufw allow from 192.168.100.0/24

    # Allow SSH (if using)
    # sudo ufw allow 22

    # Enable
    echo "y" | sudo ufw enable

    log_success "UFW configured"
}

configure_apparmor() {
    if ! command -v aa-status &>/dev/null; then
        return
    fi

    log_info "Configuring AppArmor..."

    sudo systemctl enable apparmor.service
    sudo systemctl start apparmor.service

    # Check status
    if aa-status &>/dev/null; then
        log_success "AppArmor enabled and running"
    fi
}

configure_auditd() {
    if ! command -v auditd &>/dev/null; then
        return
    fi

    log_info "Configuring auditd..."

    sudo systemctl enable auditd.service
    sudo systemctl start auditd.service

    log_success "auditd configured"
}

configure_timesync() {
    log_info "Configuring time synchronization..."

    sudo timedatectl set-ntp true
    sudo systemctl enable systemd-timesyncd.service
    sudo systemctl start systemd-timesyncd.service

    log_success "Time synchronization configured"
}

configure_btrfs_maintenance() {
    if ! command -v btrfs &>/dev/null; then
        return
    fi

    # Check if root is on BTRFS
    if ! findmnt / -t btrfs &>/dev/null; then
        return
    fi

    log_info "Configuring BTRFS maintenance..."

    sudo systemctl enable btrfs-balance.timer
    sudo systemctl enable btrfs-scrub.timer
    sudo systemctl enable btrfs-trim.timer

    log_success "BTRFS maintenance configured"
}

################################################################################
# MAIN
################################################################################

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Services Configuration                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

    # Configure specific services
    configure_timesync
    configure_docker
    configure_nordvpn
    configure_ufw
    configure_apparmor
    configure_auditd
    configure_btrfs_maintenance

    # Enable remaining services
    log_info "Enabling additional services..."
    for service in "${SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "$service"; then
            sudo systemctl enable "$service" 2>/dev/null || log_warn "Failed to enable $service"
        fi
    done

    # Disable unwanted services
    for service in "${DISABLE_SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "$service"; then
            sudo systemctl disable "$service" 2>/dev/null || true
            log_info "Disabled $service"
        fi
    done

    log_success "Services configured!"
    log_info "You may need to log out and back in for group changes to take effect."
}

main "$@"
