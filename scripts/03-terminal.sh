Manjaro Bootstrap - Terminal and shell configuration. Installs zsh, oh-my-zsh, powerlevel10k, and developer tooling setup.

#!/bin/bash
################################################################################
# Manjaro Bootstrap - Terminal & Shell Configuration
# Author: skew202
# Description: Configures zsh, oh-my-zsh, powerlevel10k, and terminal tools
#
# Order: Run AFTER authentication tools are set up (gh, hf cli need auth later)
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

################################################################################
# INSTALLATION FUNCTIONS
################################################################################

install_zsh() {
    log_step "Installing Zsh"

    if ! pacman -Q zsh &>/dev/null; then
        sudo pacman -S --noconfirm zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
    fi

    log_success "Zsh installed"

    # Change default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Changing default shell to zsh..."
        chsh -s "$(which zsh)"
        log_success "Default shell changed to zsh"
        log_warn "Log out and back in for changes to take effect"
    fi
}

install_oh_my_zsh() {
    log_step "Installing Oh My Zsh"

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh already installed"
        return
    fi

    # Install via curl
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    log_success "Oh My Zsh installed"
}

install_powerlevel10k() {
    log_step "Installing Powerlevel10k"

    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

    if [[ -d "$p10k_dir" ]]; then
        log_info "Powerlevel10k already installed"
        return
    fi

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"

    log_success "Powerlevel10k installed"

    # Configure .zshrc to use p10k
    if ! grep -q "ZSH_THEME=powerlevel10k" "$HOME/.zshrc" 2>/dev/null; then
        sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
    fi

    log_info "Run 'p10k configure' after login to customize prompt"
}

install_zsh_plugins() {
    log_step "Installing Zsh Plugins"

    # zsh-autosuggestions
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    fi

    # zsh-completions
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ]]; then
        git clone https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"
    fi

    # Enable plugins in .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$HOME/.zshrc"
    fi

    log_success "Zsh plugins installed"
}

install_fzf() {
    log_step "Installing FZF (Fuzzy Finder)"

    if pacman -Q fzf &>/dev/null; then
        log_info "FZF already installed via pacman"
    else
        sudo pacman -S --noconfirm fzf
    fi

    # Install fzf key bindings and completion
    if [[ ! -f "$HOME/.fzf.zsh" ]]; then
        "$(which fzf)" --install
    fi

    # Add to .zshrc
    if ! grep -q "fzf.zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh' >> "$HOME/.zshrc"
    fi

    log_success "FZF installed"
}

install_terminal_tools() {
    log_step "Installing Terminal Tools"

    local tools=(
        "bat"
        "ripgrep"
        "fd"
        "exa"
        "eza"
        "dust"
        "duf"
        "procs"
        "zoxide"
    )

    for tool in "${tools[@]}"; do
        if ! pacman -Q "$tool" &>/dev/null; then
            sudo pacman -S --noconfirm "$tool" 2>/dev/null || true
        fi
    done

    log_success "Terminal tools installed"

    # Configure aliases
    configure_terminal_aliases
}

configure_terminal_aliases() {
    log_info "Configuring terminal aliases..."

    local aliases="
# Modern replacements
alias ls='eza --icons'
alias ll='eza -la --icons'
alias tree='eza --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
# zoxide
eval \"\$(zoxide init zsh)\"
"

    # Add to .zshrc if not present
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "Modern replacements" "$HOME/.zshrc"; then
            echo "$aliases" >> "$HOME/.zshrc"
        fi
    fi

    log_success "Terminal aliases configured"
}

configure_git() {
    log_step "Configuring Git"

    if ! command -v git &>/dev/null; then
        return
    fi

    # Git configuration (prompts for user-specific info)
    if [[ -z "$(git config --global user.name)" ]]; then
        read -r -p "Enter your Git username: " git_username
        git config --global user.name "$git_username"
    fi

    if [[ -z "$(git config --global user.email)" ]]; then
        read -r -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    fi

    # Common git settings
    git config --global init.defaultBranch main
    git config --global core.autocrlf input
    git config --global core.pager "bat"
    git config --global diff.noprefix true

    log_success "Git configured"
}

################################################################################
# DEVELOPER TOOLING SETUP (After Auth)
################################################################################

setup_github_cli() {
    if ! command -v gh &>/dev/null; then
        return
    fi

    log_step "GitHub CLI Setup"

    log_info "Run 'gh auth login' after setup to authenticate"
    log_info "Then run: gh config set git_protocol ssh"

    log_success "GitHub CLI ready"
}

setup_huggingface_cli() {
    if ! command -v huggingface-cli &>/dev/null; then
        return
    fi

    log_step "HuggingFace CLI Setup"

    log_info "Run 'huggingface-cli login' after setup to authenticate"

    log_success "HuggingFace CLI ready"
}

setup_kubernetes_tools() {
    if ! command -v kubectl &>/dev/null; then
        return
    fi

    log_step "Kubernetes Tools Setup"

    # k9s
    if command -v k9s &>/dev/null; then
        log_info "k9s installed - run 'k9s' to manage clusters"
    fi

    # Configure kubectl
    mkdir -p "$HOME/.kube"

    log_success "Kubernetes tools ready"
}

setup_docker_tools() {
    if ! command -v docker &>/dev/null; then
        return
    fi

    log_step "Docker Tools Setup"

    # hadolint for Dockerfile linting
    if command -v hadolint &>/dev/null; then
        log_info "hadolint installed for Dockerfile linting"
    fi

    log_success "Docker tools ready"
}

################################################################################
# MAIN
################################################################################

print_post_install() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Terminal setup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Log out and back in (for shell change)"
    echo "  2. Run 'p10k configure' to customize your prompt"
    echo "  3. Authenticate with services:"
    echo "     - gh auth login"
    echo "     - huggingface-cli login"
    echo "     - 1password-cli (op signin)"
    echo "  4. Configure git credentials if not done"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          Terminal & Shell Configuration                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

    # Install zsh and frameworks
    install_zsh
    install_oh_my_zsh
    install_powerlevel10k
    install_zsh_plugins

    # Install terminal tools
    install_fzf
    install_terminal_tools

    # Configure git
    configure_git

    # Setup developer tooling (auth required later)
    setup_github_cli
    setup_huggingface_cli
    setup_kubernetes_tools
    setup_docker_tools

    print_post_install
}

main "$@"
