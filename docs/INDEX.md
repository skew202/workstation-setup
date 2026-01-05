Manjaro Bootstrap - Master Index. Links to all bootstrap scripts with installation order and rationale.

# Manjaro Bootstrap - Master Index

Complete system restoration scripts for fresh Manjaro Linux installations.

## Quick Start

```bash
# Download and run the main bootstrap script
curl -sL https://gist.githubusercontent.com/skew202/7815791cd1aba09abfe18de375a66eca/raw/00-bootstrap.sh | bash
```

## All Scripts (Run in Order)

| # | Script | Gist URL | Description |
|---|--------|----------|-------------|
| 0 | **00-hardware.sh** | [44a851a7](https://gist.github.com/skew202/44a851a7dfd711e182072ab0efc62e95) | **Hardware detection & setup** (NVIDIA, CUDA, ollama) - **RUN FIRST** |
| 1 | **00-bootstrap.sh** | [7815791c](https://gist.github.com/skew202/7815791cd1aba09abfe18de375a66eca) | Main entry point - orchestrates all scripts |
| 2 | **01-packages.sh** | [41e648cf](https://gist.github.com/skew202/41e648cfa165ad35465de042a5bdd8b0) | Install all packages (pacman + AUR) |
| 3 | **02-services.sh** | [30fb58f3](https://gist.github.com/skew202/30fb58f3756245471e2bd7692ab24bc6) | Configure systemd services |
| 4 | **03-terminal.sh** | [96dd49a4](https://gist.github.com/skew202/96dd49a45744f984abeda873edea83c9) | Configure zsh, oh-my-zsh, powerlevel10k |
| 5 | **04-hardening.sh** | [0b2792e5](https://gist.github.com/skew202/0b2792e58746c22e62ca1cf9dc42e474) | Apply security hardening |
| 6 | **05-scripts.sh** | [bb6b177c](https://gist.github.com/skew202/bb6b177c4559511f2cef44ba7216934b) | Install custom security scripts |

## Documentation

| File | Gist URL | Description |
|------|----------|-------------|
| **README.md** | [0ae6b8c7](https://gist.github.com/skew202/0ae6b8c7fd115595305d7fde4eeaa08a) | Full documentation |
| **packages.txt** | [2b81aa38](https://gist.github.com/skew202/2b81aa38cd5dc033ed882a01530f7c0e) | Complete package list (322 pacman + 19 AUR) |

## Installation Order (Flowchart)

```
┌─────────────────────────────────────────────────────────────┐
│  00-hardware.sh ───> Detect & Configure Hardware            │
│                      • NVIDIA GPU + Drivers                 │
│                      • CUDA / cuDNN                         │
│                      • Ollama (local AI)                    │
│                      • nvtop (GPU monitoring)               │
│                      • CPU microcode                        │
│                      • Laptop power management              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  00-bootstrap.sh ───> Orchestrate all scripts               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: Foundation                                        │
│  • Update system, git, curl, yay                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 2: Authentication FIRST ⭐                            │
│  • 1password (all passwords, API keys, tokens)             │
│  • google-chrome (sign in to Google services)               │
│  • gh cli (GitHub authentication)                           │
│  • huggingface-cli (HF authentication)                      │
│      (These unlock everything else)                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 3: Development Foundations                           │
│  • Docker (container runtime)                               │
│  • Node/npm/pnpm (JavaScript)                               │
│  • Python/pyenv/uv (Python)                                 │
│  • Go, Rust, Ruby (languages)                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 4: Developer Tools (Need Auth)                       │
│  • kubectl, k9s (Kubernetes)                               │
│  • doctl (DigitalOcean)                                    │
│  • supabase (Database)                                     │
│  • ollama (Local AI - uses CUDA from Phase 0)              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 5: IDEs & Editors                                    │
│  • VS Code, Cursor, Zed                                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 6: Security Tools                                    │
│  • NordVPN, nmap, wireshark, etc.                           │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 7: Shell & Terminal                                  │
│  • zsh, oh-my-zsh, powerlevel10k                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 8: Services & Hardening                              │
│  • Enable Docker/VPN/NVIDIA services                        │
│  • Apply security hardening (sysctl, firewall)              │
└─────────────────────────────────────────────────────────────┘
```

## Hardware-Specific Setup (00-hardware.sh)

The hardware script runs **FIRST** and automatically detects:

### GPU Configuration
| GPU Type | Packages Installed | Monitoring |
|----------|-------------------|------------|
| NVIDIA | nvidia-utils, nvidia-settings, lib32-nvidia-utils | nvtop |
| AMD | mesa, xf86-video-amdgpu, lib32-mesa-vdpau | radeontop |
| Intel | xf86-video-intel, vulkan-intel | intel_gpu_top |

### AI / CUDA Setup
| Component | Package | Purpose |
|-----------|---------|---------|
| CUDA Toolkit | cuda | NVIDIA CUDA |
| Deep Learning | cudnn | CUDA Deep Neural Network |
| Local AI | ollama-cuda | Local LLMs with GPU acceleration |
| GPU Monitor | nvtop | Real-time GPU monitoring |

### After Hardware Script
```bash
# Verify NVIDIA GPU
nvidia-smi

# Monitor GPU (htop-style)
nvtop

# Pull and run local AI
ollama pull llama3.2
ollama run llama3.2
```

### Power Management (Laptops)
- **power-profiles-daemon** - GNOME power profiles
- **tlp** - Advanced laptop power management (optional)
- **cpupower** - CPU frequency scaling

## Post-Installation Checklist

After running all scripts:

- [ ] **Reboot** (required for NVIDIA drivers and kernel changes)
- [ ] Run `p10k configure` to customize prompt
- [ ] Sign in to **1Password**
- [ ] Run `gh auth login` for GitHub
- [ ] Run `huggingface-cli login` for HF
- [ ] Sign in to **Google Chrome**
- [ ] Run `nordvpn-helper nordlynx` to configure VPN
- [ ] Run `security-audit` to check system
- [ ] Run `sudo lynis audit system` for full audit
- [ ] Test GPU: `nvidia-smi` or `nvtop`
- [ ] Test Ollama: `ollama run llama3.2`

## Package Breakdown

### Total Packages
- **322** pacman packages
- **19** AUR packages
- **25+** systemd services

### Key Categories
| Category | Count | Examples |
|----------|-------|----------|
| Development | ~50 | git, docker, kubectl, python, node, go, rust |
| Security | ~15 | nmap, wireshark, lynis, rkhunter, nordvpn |
| AI/ML | ~10 | cuda, cudnn, ollama-cuda, python-pytorch-cuda |
| GNOME/Desktop | ~80 | gnome-shell, extensions, apps |
| Productivity | ~20 | vscode, cursor, zed, libreoffice, chrome |

## Author

**skew202** - [github.com/skew202](https://github.com/skew202)

## License

MIT - Free to use and modify.
