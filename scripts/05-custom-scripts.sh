Manjaro Bootstrap - Custom scripts installer. Installs security-audit, wifi-safety-check, and nordvpn-helper scripts.

#!/bin/bash
################################################################################
# Manjaro Bootstrap - Custom Scripts Installer
# Author: skew202
# Description: Installs custom security and utility scripts
#
# Scripts installed:
#   - security-audit: Comprehensive system security audit
#   - wifi-safety-check: Public WiFi safety scanner
#   - nordvpn-helper: NordVPN management tool
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step() { echo -e "\n${CYAN}═══ $1 ═══${NC}"; }

# Script directory
SCRIPT_DIR="$HOME/.local/bin"
SCRIPTS_BASE_URL="${SCRIPTS_BASE_URL:-https://gist.githubusercontent.com/skew202}"

################################################################################
# SCRIPT INSTALLER
################################################################################

install_script() {
    local name="$1"
    local gist_id="$2"
    local dest="$SCRIPT_DIR/$name"

    # Create directory if needed
    mkdir -p "$SCRIPT_DIR"

    log_info "Installing $name..."

    # Download script
    if curl -fsSL "https://gist.githubusercontent.com/skew202/$gist_id/raw/$name" -o "$dest"; then
        chmod +x "$dest"
        log_success "Installed $name"
    else
        log_warn "Failed to download $name"
        return 1
    fi
}

################################################################################
# SECURITY SCRIPTS
################################################################################

install_security_audit() {
    log_step "Installing Security Audit Script"

    # Gist ID for security-audit (update after creating gist)
    local gist_id="2ecaa06954f03f0038b888695753b41b"

    install_script "security-audit" "$gist_id"

    log_info "Run with: ~/.local/bin/security-audit"
}

install_wifi_safety_check() {
    log_step "Installing WiFi Safety Check Script"

    # Gist ID for wifi-safety-check (update after creating gist)
    local gist_id="1dc8cea585f1b85412d559671c1caa06"

    install_script "wifi-safety-check" "$gist_id"

    log_info "Run with: ~/.local/bin/wifi-safety-check"
}

install_nordvpn_helper() {
    log_step "Installing NordVPN Helper Script"

    # Gist ID for nordvpn-helper (update after creating gist)
    local gist_id="05443f35321301b78205f84a15b6fdf5"

    install_script "nordvpn-helper" "$gist_id"

    log_info "Run with: ~/.local/bin/nordvpn-helper"
}

################################################################################
# UTILITY SCRIPTS
################################################################################

create_aliases() {
    log_step "Creating Command Aliases"

    local aliases_file="$HOME/.zshrc.local"
    local aliases="
# Security Scripts Aliases
alias sec-audit='$HOME/.local/bin/security-audit'
alias wifi-check='$HOME/.local/bin/wifi-safety-check'
alias vpn='$HOME/.local/bin/nordvpn-helper'

# Quick VPN commands
alias vpn-on='nordvpn-helper connect'
alias vpn-off='nordvpn-helper disconnect'
alias vpn-status='nordvpn-helper status'
"

    if [[ ! -f "$aliases_file" ]]; then
        echo "$aliases" > "$aliases_file"
    elif ! grep -q "Security Scripts Aliases" "$aliases_file"; then
        echo "$aliases" >> "$aliases_file"
    fi

    log_success "Aliases created in $aliases_file"
}

create_systemd_units() {
    log_step "Creating Optional Systemd Units"

    # Example: Weekly security scan timer
    local timer_dir="$HOME/.config/systemd/user"
    mkdir -p "$timer_dir"

    # Security scan service
    cat > "$timer_dir/security-scan.service" << 'EOF'
[Unit]
Description=Weekly Security Audit
After=network-online.target

[Service]
Type=oneshot
ExecStart=%h/.local/bin/security-audit
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

    # Security scan timer
    cat > "$timer_dir/security-scan.timer" << 'EOF'
[Unit]
Description=Weekly Security Audit Timer
Requires=security-scan.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

    log_info "To enable weekly security scans:"
    log_info "  systemctl --user enable security-scan.timer"
    log_info "  systemctl --user start security-scan.timer"
}

################################################################################
# DESKTOP INTEGRATION
################################################################################

create_desktop_shortcuts() {
    log_step "Creating Desktop Shortcuts"

    local apps_dir="$HOME/.local/share/applications"
    mkdir -p "$apps_dir"

    # Security Audit
    cat > "$apps_dir/security-audit.desktop" << EOF
[Desktop Entry]
Name=Security Audit
Comment=Run comprehensive security audit
Exec=alacritty --title \"Security Audit\" -e $HOME/.local/bin/security-audit
Icon=security-high
Terminal=true
Type=Application
Categories=System;Security;
EOF

    # WiFi Safety Check
    cat > "$apps_dir/wifi-safety-check.desktop" << EOF
[Desktop Entry]
Name=WiFi Safety Check
Comment=Check public WiFi safety
Exec=alacritty --title \"WiFi Safety\" -e $HOME/.local/bin/wifi-safety-check
Icon=network-wireless
Terminal=true
Type=Application
Categories=System;Network;
EOF

    log_success "Desktop shortcuts created"
}

################################################################################
# SUMMARY
################################################################################

print_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Custom scripts installed!${NC}"
    echo ""
    echo "Scripts available:"
    echo "  • security-audit    - Full system security audit"
    echo "  • wifi-safety-check - Public WiFi scanner"
    echo "  • nordvpn-helper   - VPN management"
    echo ""
    echo "Quick commands:"
    echo "  • sec-audit         - Run security audit"
    echo "  • wifi-check        - Check WiFi safety"
    echo "  • vpn               - VPN helper"
    echo "  • vpn-on/off        - Connect/disconnect VPN"
    echo ""
    echo "Next steps:"
    echo "  1. Run 'security-audit' to check your system"
    echo "  2. Run 'nordvpn-helper nordlynx' to configure VPN"
    echo "  3. Run 'wifi-safety-check' when on public WiFi"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

################################################################################
# MAIN
################################################################################

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Custom Scripts Installer                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

    # Install scripts
    install_security_audit
    install_wifi_safety_check
    install_nordvpn_helper

    # Create integration
    create_aliases
    create_systemd_units
    create_desktop_shortcuts

    print_summary
}

main "$@"
