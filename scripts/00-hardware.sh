Manjaro Bootstrap - Hardware Setup. Detects and configures NVIDIA GPU, CUDA, ollama, nvtop, microcode, and laptop power management. Run FIRST before other scripts.

#!/bin/bash
################################################################################
# Manjaro Bootstrap - Hardware Setup & Detection
# Author: skew202
# Description: Detects and configures hardware (NVIDIA GPU, CUDA, AI tools)
#
# Order: Run FIRST, before package installation
# This ensures proper drivers are installed before dependent packages
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
# HARDWARE DETECTION
################################################################################

detect_gpu() {
    log_step "Detecting GPU Hardware"

    local gpu_info
    gpu_info=$(lspci | grep -i vga)

    log_info "GPU detected:"
    echo "$gpu_info"

    if echo "$gpu_info" | grep -qi "nvidia"; then
        GPU_VENDOR="nvidia"
        log_success "NVIDIA GPU detected"
    elif echo "$gpu_info" | grep -qi "amd"; then
        GPU_VENDOR="amd"
        log_success "AMD GPU detected"
    elif echo "$gpu_info" | grep -qi "intel"; then
        GPU_VENDOR="intel"
        log_success "Intel GPU detected"
    else
        GPU_VENDOR="unknown"
        log_warn "Unknown or no GPU detected"
    fi
}

detect_cpu() {
    log_step "Detecting CPU"

    local cpu_vendor
    cpu_vendor=$(lscpu | grep "Vendor ID" | awk '{print $3}')

    log_info "CPU Vendor: $cpu_vendor"

    if [[ "$cpu_vendor" == *"AuthenticAMD"* ]]; then
        CPU_VENDOR="amd"
        log_success "AMD CPU detected"
    elif [[ "$cpu_vendor" == *"GenuineIntel"* ]]; then
        CPU_VENDOR="intel"
        log_success "Intel CPU detected"
    else
        CPU_VENDOR="unknown"
        log_warn "Unknown CPU vendor"
    fi
}

detect_additional_hardware() {
    log_step "Detecting Additional Hardware"

    # Check for battery (laptop)
    if ls /sys/class/power_supply/BAT* &>/dev/null; then
        IS_LAPTOP=true
        log_info "Laptop detected (battery found)"
    else
        IS_LAPTOP=false
        log_info "Desktop detected (no battery)"
    fi

    # Check for Bluetooth
    if lspci | grep -qi bluetooth; then
        HAS_BLUETOOTH=true
        log_info "Bluetooth adapter detected"
    fi

    # Check for fingerprint reader
    if lspci | grep -qi fingerprint; then
        HAS_FINGERPRINT=true
        log_info "Fingerprint reader detected"
    fi

    # Check for webcam
    if ls /dev/video* &>/dev/null; then
        log_info "Webcam detected"
    fi

    # Total RAM
    local total_mem
    total_mem=$(free -h | grep "^Mem:" | awk '{print $2}')
    log_info "Total RAM: $total_mem"
}

print_hardware_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Hardware Detection Summary${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo "  GPU:    ${GPU_VENDOR:-unknown}"
    echo "  CPU:    ${CPU_VENDOR:-unknown}"
    echo "  Type:   $([ "$IS_LAPTOP" = true ] && echo "Laptop" || echo "Desktop")"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# NVIDIA GPU SETUP
################################################################################

setup_nvidia() {
    if [[ "$GPU_VENDOR" != "nvidia" ]]; then
        return
    fi

    log_step "NVIDIA GPU Setup"

    local nvidia_packages=(
        "nvidia-utils"
        "nvidia-settings"
        "opencl-nvidia"
    )

    # 32-bit libraries for Steam/Wine
    local nvidia_32=(
        "lib32-nvidia-utils"
        "lib32-opencl-nvidia"
    )

    # Check what's already installed
    local to_install=()
    for pkg in "${nvidia_packages[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    for pkg in "${nvidia_32[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing NVIDIA packages..."
        sudo pacman -S --noconfirm "${to_install[@]}"
        log_success "NVIDIA drivers installed"
    else
        log_info "NVIDIA packages already installed"
    fi

    # Configure NVIDIA Prime (if using hybrid graphics)
    if lspci | grep -qi "nvidia.*vga" && lspci | grep -qi "intel.*vga\|amd.*vga"; then
        log_info "Hybrid graphics detected"
        if ! pacman -Q nvidia-prime &>/dev/null; then
            sudo pacman -S --noconfirm nvidia-prime
            log_success "NVIDIA Prime installed (optimus support)"
        fi
    fi

    # NVIDIA suspend/resume fix (laptops)
    if [[ "$IS_LAPTOP" == true ]]; then
        setup_nvidia_pm
    fi
}

setup_nvidia_pm() {
    log_info "Configuring NVIDIA power management for laptop..."

    # Create NVIDIA power management service
    sudo tee /etc/systemd/system/nvidia-suspend.service > /dev/null << 'EOF'
[Unit]
Description=NVIDIA Suspend
Before=sleep.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo mem > /sys/power/state'
ExecStop=/bin/bash -c 'rmmod nvidia_uvm nvidia_drm nvidia; modprobe nvidia nvidia_drm'
TimeoutSec=0

[Install]
WantedBy=suspend.target
EOF

    sudo tee /etc/systemd/system/nvidia-resume.service > /dev/null << 'EOF'
[Unit]
Description=NVIDIA Resume
After=suspend.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'modprobe nvidia nvidia_drm'
TimeoutSec=0

[Install]
WantedBy=resume.target
EOF

    sudo systemctl enable nvidia-suspend.service nvidia-resume.service 2>/dev/null || true

    log_success "NVIDIA power management configured"
}

test_nvidia() {
    if [[ "$GPU_VENDOR" != "nvidia" ]]; then
        return
    fi

    log_step "Testing NVIDIA Setup"

    if command -v nvidia-smi &>/dev/null; then
        log_info "nvidia-smi output:"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
        log_success "NVIDIA GPU is working"
    else
        log_warn "nvidia-smi not found - may need reboot"
    fi
}

################################################################################
# CUDA / AI SETUP
################################################################################

setup_cuda() {
    if [[ "$GPU_VENDOR" != "nvidia" ]]; then
        log_info "CUDA requires NVIDIA GPU - skipping"
        return
    fi

    log_step "CUDA & AI Framework Setup"

    local cuda_packages=(
        "cuda"
        "cudnn"
    )

    local to_install=()
    for pkg in "${cuda_packages[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing CUDA packages..."
        log_warn "CUDA packages are large - this may take a while"
        sudo pacman -S --noconfirm "${to_install[@]}"
        log_success "CUDA installed"
    else
        log_info "CUDA already installed"
    fi

    # Python AI frameworks
    if command -v pip &>/dev/null || command -v uv &>/dev/null; then
        log_info "Setting up Python AI packages..."

        local ai_packages=(
            "torch"
            "torchvision"
            "transformers"
            "accelerate"
        )

        log_info "Install with: uv pip install torch torchvision transformers accelerate"
    fi
}

setup_ollama() {
    log_step "Ollama (Local AI) Setup"

    # Check if NVIDIA GPU available
    if [[ "$GPU_VENDOR" != "nvidia" ]]; then
        log_info "Ollama works best with NVIDIA GPU - will use CPU"
        OLLAMA_CUDA=""
    else
        OLLAMA_CUDA="cuda"
    fi

    # Install ollama-cuda package
    local ollama_pkg="ollama${OLLAMA_CUDA:+-cuda}"

    if pacman -Q "$ollama_pkg" &>/dev/null; then
        log_info "$ollama_pkg already installed"
    else
        log_info "Installing $ollama_pkg..."
        sudo pacman -S --noconfirm "$ollama_pkg" 2>/dev/null || \
        yay -S --noconfirm "$ollama_pkg" 2>/dev/null || \
        log_warn "$ollama_pkg not found in repos"
    fi

    # Enable ollama service
    if systemctl list-unit-files | grep -q "ollama.service"; then
        sudo systemctl enable --now ollama.service 2>/dev/null || true
        log_success "Ollama service enabled"
    fi

    log_info "Ollama commands:"
    echo "  ollama list              - List installed models"
    echo "  ollama pull llama3.2     - Download a model"
    echo "  ollama run llama3.2      - Run a model"
    echo "  ollama serve             - Start API server"
}

setup_nvtop() {
    log_step "NVTOP Setup (GPU Monitor)"

    if [[ "$GPU_VENDOR" != "nvidia" ]]; then
        log_info "NVTOP is for NVIDIA GPUs - skipping"
        return
    fi

    if pacman -Q nvtop &>/dev/null; then
        log_info "nvtop already installed"
        return
    fi

    sudo pacman -S --noconfirm nvtop 2>/dev/null || \
    yay -S --noconfirm nvtop 2>/dev/null || \
    log_warn "nvtop not found"

    if command -v nvtop &>/dev/null; then
        log_success "nvtop installed"
        log_info "Run with: nvtop"
    fi
}

################################################################################
# CPU MICROCODE
################################################################################

setup_microcode() {
    log_step "CPU Microcode Setup"

    if [[ "$CPU_VENDOR" == "amd" ]]; then
        if pacman -Q amd-ucode &>/dev/null; then
            log_info "amd-ucode already installed"
        else
            sudo pacman -S --noconfirm amd-ucode
            log_success "amd-ucode installed"
        fi
    elif [[ "$CPU_VENDOR" == "intel" ]]; then
        if pacman -Q intel-ucode &>/dev/null; then
            log_info "intel-ucode already installed"
        else
            sudo pacman -S --noconfirm intel-ucode
            log_success "intel-ucode installed"
        fi
    fi

    # Check if microcode is loaded in bootloader
    if [[ -f /boot/grub/grub.cfg ]]; then
        if grep -q "microcode" /boot/grub/grub.cfg; then
            log_info "Microcode enabled in GRUB"
        else
            log_warn "Microcode may not be enabled in GRUB"
            log_info "Run: sudo grub-mkconfig -o /boot/grub/grub.cfg"
        fi
    fi
}

################################################################################
# OTHER HARDWARE
################################################################################

setup_firmware() {
    log_step "Firmware Packages"

    local firmware_packages=(
        "sof-firmware"      # Sound
        "linux-firmware"    # General firmware
    )

    for pkg in "${firmware_packages[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            sudo pacman -S --noconfirm "$pkg" 2>/dev/null || true
        fi
    done

    log_success "Firmware packages installed"
}

setup_power_management() {
    if [[ "$IS_LAPTOP" != true ]]; then
        return
    fi

    log_step "Laptop Power Management"

    # Enable power-profiles-daemon
    if systemctl list-unit-files | grep -q "power-profiles-daemon.service"; then
        sudo systemctl enable --now power-profiles-daemon.service
        log_success "Power profiles enabled"
        log_info "Control with: gnome-power-statistics or powerprofilesctl"
    fi

    # TLP (alternative power management)
    if confirm "Install TLP for advanced power management?"; then
        sudo pacman -S --noconfirm tlp tlp-rdw 2>/dev/null || true
        sudo systemctl enable tlp.service tlp-sleep.service
        log_success "TLP installed"
        log_info "Status: sudo tlp-stat"
    fi

    # CPU frequency scaling
    if pacman -Q cpupower &>/dev/null; then
        sudo systemctl enable cpupower.service
        log_info "cpupower enabled - control with: sudo cpupower frequency-set"
    fi
}

################################################################################
# VERIFICATION
################################################################################

verify_setup() {
    log_step "Hardware Verification"

    echo -e "${CYAN}GPU Information:${NC}"
    if command -v nvidia-smi &>/dev/null; then
        nvidia-smi --query-gpu=name,driver_version,memory.total,temperature.gpu --format=csv,noheader 2>/dev/null || \
        nvidia-smi
    elif command -v radeontop &>/dev/null; then
        echo "AMD GPU detected - use radeontop for monitoring"
    elif command -v intel_gpu_top &>/dev/null; then
        echo "Intel GPU detected - use intel_gpu_top for monitoring"
    else
        lspci | grep -i vga
    fi

    echo -e "\n${CYAN}CUDA Information:${NC}"
    if command -v nvcc &>/dev/null; then
        nvcc --version
    else
        echo "CUDA toolkit not found in PATH"
    fi

    echo -e "\n${CYAN}Python PyTorch CUDA Support:${NC}"
    if command -v python &>/dev/null; then
        python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')" 2>/dev/null || \
        echo "PyTorch not installed or not accessible"
    fi

    echo -e "\n${CYAN}Ollama Status:${NC}"
    if systemctl is-active --quiet ollama.service; then
        echo "Ollama service: running"
        if command -v ollama &>/dev/null; then
            echo "Installed models:"
            ollama list 2>/dev/null || echo "None yet - run 'ollama pull llama3.2'"
        fi
    else
        echo "Ollama service: not running"
    fi
}

################################################################################
# SUMMARY
################################################################################

print_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Hardware setup complete!${NC}"
    echo ""
    echo "Next steps:"
    if [[ "$GPU_VENDOR" == "nvidia" ]]; then
        echo "  • Reboot to load NVIDIA drivers"
        echo "  • Run 'nvtop' to monitor GPU"
        echo "  • Run 'nvidia-smi' to check GPU status"
    fi
    if command -v ollama &>/dev/null; then
        echo "  • Pull a model: ollama pull llama3.2"
        echo "  • Run a model: ollama run llama3.2"
    fi
    echo "  • Continue with package installation: ./01-packages.sh"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

################################################################################
# MAIN
################################################################################

confirm() {
    local prompt="$1"
    read -r -p "$prompt [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Hardware Setup & Detection                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

    # Detect all hardware
    detect_gpu
    detect_cpu
    detect_additional_hardware
    print_hardware_summary

    # Setup based on detected hardware
    setup_microcode
    setup_firmware

    if [[ "$GPU_VENDOR" == "nvidia" ]]; then
        setup_nvidia
        setup_cuda
        setup_nvtop
    fi

    setup_ollama

    if [[ "$IS_LAPTOP" == true ]]; then
        setup_power_management
    fi

    # Verify setup
    verify_setup
    print_summary
}

main "$@"
