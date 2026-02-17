# Ubuntu Nix Config - Auto NVIDIA Version Management

Declarative Ubuntu+Nix+home-manager setup with automatic NVIDIA driver version detection.

## 🚀 Quick Start

```bash
# Clone
git clone https://github.com/Tramscan/ubuntu-nix-config.git ~/.config/nix

# Run interactive onboarding (first-time setup)
./scripts/onboard.sh

# Or configure manually, then switch
home-manager switch --flake ~/.config/nix
```

## ✨ New Features

### A. Auto-Detection Toggle
Set once, forget about it:
```nix
nvidiaManagement.enableAutoDetection = true;  # Automatically detect driver version
nvidiaManagement.regenerateDesktopFile = true; # Update hyprland.desktop at boot
```

### B. Manual Version Override
Pin a specific version for stability or downgrade:
```nix
nvidiaManagement.manualVersion = "570.133.07";  # Pin this version
# OR
nvidiaManagement.manualVersion = null;  # Use auto-detect
```

### C. Multi-System Support
```bash
# Onboard a new system (laptop, desktop, etc.)
./scripts/onboard.sh

# Creates:
# ~/.config/nix/systems/my-laptop.nix
# ~/.config/nix/active-system
```

## 🖥️ nixGL Variants

Choose your GPU wrapper:
| Variant | Use Case |
|---------|----------|
| `none` | No wrapper, use system OpenGL |
| `default` | Auto-detect GPU |
| `nvidia` | NVIDIA proprietary (with version management) |
| `bumblebee` | NVIDIA Optimus hybrid |
| `intel` | Intel integrated |

## 📋 Commands

```bash
# Check status
./scripts/nvidia-version-manager.sh status

# Set manual override (pin version)
./scripts/nvidia-version-manager.sh set-override 570.133.07

# Clear override (use auto-detect)
./scripts/nvidia-version-manager.sh clear-override

# Force update configs
./scripts/nvidia-version-manager.sh update

# Re-run onboarding
./scripts/onboard.sh --force
```

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `~/.config/nix/nvidia-version.conf` | Cached version info (auto-generated) |
| `~/.config/nix/nvidia-version-override` | Manual version override |
| `~/.config/nix/systems/<name>.nix` | Per-system config |
| `~/.config/nix/active-system` | Link to active config |

## 🏗️ Architecture

```
flake.nix
├── home-manager/
│   ├── home.nix              (main config)
│   ├── nvidia-config.nix     (NVIDIA options)
│   ├── system-config.nix       (system type options)
│   └── systems/
│       └── laptop-template.nix (example)
└── scripts/
    ├── onboard.sh              (setup wizard)
    └── nvidia-version-manager.sh (CLI tool)
```

## 🔌 Systemd Service

The `nvidia-version-manager` user service runs at login:
- Detects current NVIDIA driver version
- Updates `~/.config/nix/nvidia-version.conf`
- Regenerates `/usr/share/wayland-sessions/hyprland.desktop`

This happens **before** Hyprland starts, so you won't get a black screen after driver updates.

## Example Configurations

### Desktop with NVIDIA (auto-detect)
```nix
{
  systemConfig.systemType = "desktop";
  systemConfig.nixGLVariant = "nvidia";
  
  nvidiaManagement.enableAutoDetection = true;
  nvidiaManagement.regenerateDesktopFile = true;
}
```

### Laptop with Intel
```nix
{
  systemConfig.systemType = "laptop";
  systemConfig.nixGLVariant = "intel";
}
```

### Desktop with pinned version
```nix
{
  systemConfig.nixGLVariant = "nvidia";
  nvidiaManagement.manualVersion = "570.86.16";  # Pin older version
}
```

## Troubleshooting

**Hyprland won't start after NVIDIA update:**
1. Switch to TTY (Ctrl+Alt+F3)
2. Run: `./scripts/nvidia-version-manager.sh update`
3. Or: `sudo /usr/share/wayland-sessions/hyprland.desktop` to check what's used

**Wrong version detected:**
```bash
# Pin manually
./scripts/nvidia-version-manager.sh set-override $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1 | tr -d ' ')
```

**System not using nixGL:**
Check `~/.config/nix/active-system` exists and points to your system config.

## License

MIT - do what you want.