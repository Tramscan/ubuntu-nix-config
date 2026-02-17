# R.0 - Repository Overview

## Project: Just Enough Nix

A declarative Ubuntu + Nix + home-manager configuration with automatic NVIDIA driver version management.

### What This Is

This repository provides a complete, reproducible desktop environment setup for Ubuntu systems using:
- **Nix** - The purely functional package manager
- **home-manager** - Declarative user environment management
- **Hyprland** - A dynamic tiling Wayland compositor
- **NVIDIA** - Proprietary driver support with version auto-detection

### Why This Exists

Setting up NVIDIA + Wayland + Nix on non-NixOS systems is painful. Driver updates break the nixGL wrapper, requiring manual fixes. This repo solves that with automatic version detection.

### Repository Structure

```
ubuntu-nix-config/
├── home-manager/
│   ├── home.nix              # Main home configuration
│   ├── nvidia-config.nix     # NVIDIA version management options
│   ├── system-config.nix     # System type and nixGL variant options
│   ├── apps/                 # Application-specific configs
│   │   ├── hyprland/
│   │   ├── alacritty/
│   │   ├── nixvim/
│   │   └── ...
│   └── systems/              # Per-system configurations
│       └── laptop-template.nix
├── scripts/
│   ├── onboard.sh            # Interactive setup wizard
│   └── nvidia-version-manager.sh
├── flake.nix                 # Nix flake definition
└── README.md
```

### Key Features

1. **Auto-detect NVIDIA drivers** - Version detected at boot, configs regenerated
2. **Manual version override** - Pin specific versions for stability
3. **Multi-system support** - Desktop, laptop, headless, minimal
4. **Multiple nixGL variants** - none, default, nvidia, bumblebee, intel
5. **Interactive onboarding** - `onboard.sh` for easy setup

### Quick Start

```bash
# Clone to .config/nix
git clone https://github.com/Tramscan/ubuntu-nix-config.git ~/.config/nix

# Run onboarding wizard
cd ~/.config/nix
./scripts/onboard.sh

# Apply configuration
home-manager switch --flake ~/.config/nix
```

### Requirements

- Ubuntu 22.04+ (or compatible)
- Nix package manager with flakes enabled
- NVIDIA proprietary drivers (for NVIDIA systems)
- (Optional) Tailscale for dashboard access

### Architecture

The configuration uses a modular approach:
- **system-config.nix** - Defines system type and nixGL variant
- **nvidia-config.nix** - Manages NVIDIA version detection/override
- **home.nix** - Main configuration importing modules
- **onboard.sh** - Interactive wizard generating system-specific configs

### Version Management

The `nvidia-version-manager.sh` script:
- Detects current NVIDIA driver version
- Updates `~/.config/nix/nvidia-version.conf`
- Regenerates `/usr/share/wayland-sessions/hyprland.desktop`
- Runs as systemd service before display manager

### Development

This is a living configuration. Update as needed:
```
# Add new application
mkdir home-manager/apps/myapp
echo '{ config, pkgs, ... }: { home.packages = [ pkgs.myapp ]; }' > home-manager/apps/myapp/default.nix

# Import in home.nix
# Add to imports list
```

### Troubleshooting

- **Hyprland won't start**: Check NVIDIA version with `nvidia-version-manager.sh status`
- **Unfree packages blocked**: Set `allow-unfree = true` in nix.conf
- **Flake impure**: Use `home-manager switch --impure` for external file access

### Links

- Nix: https://nixos.org/
- home-manager: https://github.com/nix-community/home-manager
- Hyprland: https://hyprland.org/
- nixGL: https://github.com/nix-community/nixGL

---

*Last updated: $(date)*
