Manjaro Bootstrap - README documentation. Complete guide for restoring a Manjaro laptop from scratch.

# Manjaro Bootstrap Scripts

Complete system restoration scripts for fresh Manjaro Linux installations.

**Author:** skew202
**Version:** 1.0

## Overview

This collection of scripts automates the setup of a Manjaro laptop from scratch. Each script handles a specific aspect of the installation, allowing you to run them independently or as a complete set.

## Script Order (Optimal)

The scripts are designed to be run in the following order for optimal results:

```
1. 00-bootstrap.sh     - Main entry point (orchestrates all scripts)
2. 01-packages.sh      - Install all packages (pacman + AUR)
3. 02-services.sh      - Configure systemd services
4. 03-terminal.sh      - Configure shell, zsh, p10k
5. 04-hardening.sh     - Apply security hardening
6. 05-scripts.sh       - Install custom security scripts
```

## Installation Order Rationale

### Phase 1: Foundation (00-bootstrap.sh)
- Update system
- Install base tools (git, curl, yay)

### Phase 2: Authentication (First) ⭐
These tools enable everything else:
- **1password** - Stores all passwords, API keys, tokens
- **1password-cli** - CLI access to credentials
- **google-chrome** - Sign in to Google (Gmail, Drive, etc.)
- **gh cli** - GitHub authentication
- **huggingface-cli** - HuggingFace authentication

### Phase 3: Development Foundations
- **Docker** - Required for many tools
- **Node/npm/pnpm** - JavaScript toolchain
- **Python/pyenv/uv** - Python toolchain
- **Go, Rust, Ruby** - Language toolchains

### Phase 4: Developer Tools (Require Auth)
- **kubectl, k9s** - Kubernetes management
- **doctl** - DigitalOcean CLI
- **supabase** - Database/backend
- **ollama** - Local AI models

### Phase 5: IDEs & Editors
- **VS Code**
- **Cursor**
- **Zed**

### Phase 6: Security
- **NordVPN** - VPN client
- **Security tools** - nmap, wireshark, etc.

### Phase 7: Shell & Terminal
- **zsh**
- **oh-my-zsh**
- **powerlevel10k**

### Phase 8: Services & Hardening
- **systemd services** - Enable Docker, VPN, etc.
- **security hardening** - sysctl, firewall, AppArmor

## Quick Start

### Full Installation (Recommended)

```bash
# Download and run the main bootstrap script
curl -sL https://gist.githubusercontent.com/skew202/<BOOTSTRAP_GIST_ID>/raw/00-bootstrap.sh | bash
```

### Step-by-Step Installation

```bash
# Clone/download all scripts to a directory
git clone https://gist.github.com/<username>/<gist_id> ~/bootstrap
cd ~/bootstrap

# Run scripts in order
sudo ./01-packages.sh --all
sudo ./02-services.sh
./03-terminal.sh
sudo ./04-hardening.sh
./05-scripts.sh

# Reboot to apply all changes
sudo reboot
```

## Individual Scripts

### 00-bootstrap.sh
**Purpose:** Main entry point that orchestrates all other scripts.

**Features:**
- System checks (internet, root, etc.)
- Interactive menu to select what to install
- Downloads other scripts automatically

### 01-packages.sh
**Purpose:** Install all packages (pacman + AUR).

**Categories:**
- Core system
- Development tools
- Security tools
- Network & VPN
- Productivity apps
- Multimedia
- AI/ML tools
- And more...

**Usage:**
```bash
# Install all categories
./01-packages.sh --all

# Interactive (prompt for each category)
./01-packages.sh
```

### 02-services.sh
**Purpose:** Configure and enable systemd services.

**Services Configured:**
- Docker
- NordVPN
- UFW firewall
- AppArmor
- auditd
- BTRFS maintenance
- Time synchronization

### 03-terminal.sh
**Purpose:** Configure shell, terminal, and development tooling.

**Installs:**
- zsh
- oh-my-zsh
- powerlevel10k
- zsh plugins
- fzf
- Modern terminal tools (bat, ripgrep, fd, eza)

**Configures:**
- Git (prompts for user info)
- GitHub CLI setup instructions
- HuggingFace CLI setup
- Kubernetes tools

### 04-hardening.sh
**Purpose:** Apply security hardening.

**Hardening Applied:**
- Kernel sysctl hardening
- UFW firewall configuration
- AppArmor enablement
- auditd configuration
- File permission hardening
- Malware scanner setup

**Follow-up:**
```bash
sudo lynis audit system
```

### 05-scripts.sh
**Purpose:** Install custom security and utility scripts.

**Scripts Installed:**
- `security-audit` - Comprehensive system audit
- `wifi-safety-check` - Public WiFi scanner
- `nordvpn-helper` - VPN management

**Aliases Created:**
- `sec-audit`
- `wifi-check`
- `vpn` / `vpn-on` / `vpn-off`

## Post-Installation Checklist

After running all scripts:

- [ ] Reboot the system
- [ ] Run `p10k configure` to customize prompt
- [ ] Sign in to 1Password
- [ ] Run `gh auth login` for GitHub
- [ ] Run `huggingface-cli login` for HF
- [ ] Sign in to Google Chrome
- [ ] Run `nordvpn-helper nordlynx` to configure VPN
- [ ] Run `security-audit` to check system
- [ ] Run `sudo lynis audit system` for full audit

## Customization

### Package Lists

Edit `01-packages.sh` to add/remove packages:

```bash
YOUR_CATEGORY_PACKAGES=(
    "package1"
    "package2"
    "package3"
)
```

### Services

Edit `02-services.sh` to enable/disable services:

```bash
SERVICES=(
    "service1.service"
    "service2.service"
)
```

### Kernel Hardening

Edit `04-hardening.sh` to modify sysctl settings.

## Troubleshooting

### "command not found" errors
Run scripts in order. Later scripts depend on packages installed by earlier scripts.

### Permission errors
Some scripts require sudo. Run with appropriate privileges.

### AUR packages fail to build
Update system first: `sudo pacman -Syu`

### Network issues
Ensure internet connection before starting. Bootstrap checks for this.

## Security Notes

- These scripts are public - don't store sensitive data in them
- API keys and credentials should be stored in 1Password
- Personal configuration files should be in a private repo

## Contributing

Feel free to fork and modify these scripts for your own setup.

## License

MIT - Do whatever you want with these scripts.

---

**Last Updated:** 2026-01-03
**Tested On:** Manjaro Linux (Rolling Release)
