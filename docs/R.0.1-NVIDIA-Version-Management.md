# R.0.1 - NVIDIA Version Management & Multi-System Support

## Summary

This revision adds automatic NVIDIA driver version detection, manual version pinning, and multi-system onboarding support.

## New Features

### 1. Auto-Detection Toggle (Feature A)

**Problem**: NVIDIA driver updates require manual editing of:
- `/usr/share/wayland-sessions/hyprland.desktop`
- `home.nix` references to `nixGLNvidia-[version]`

**Solution**: Systemd service runs before display manager, auto-detects version

**Config**:
```nix
nvidiaManagement.enableAutoDetection = true;  # Auto-detect
# OR
nvidiaManagement.enableAutoDetection = false; # Use manual
```

### 2. Manual Version Override (Feature B)

**Problem**: Can't downgrade or pin specific versions

**Solution**: Optional manual version setting

**Config**:
```nix
nvidiaManagement.manualVersion = "570.133.07";  # Pin this version
# OR
nvidiaManagement.manualVersion = null;  # Use auto-detect
```

**CLI**:
```bash
./scripts/nvidia-version-manager.sh set-override 570.133.07
./scripts/nvidia-version-manager.sh clear-override
```

### 3. Multi-System Support

**Problem**: Same config for desktop (RTX 4090) and laptop (GTX 1050)

**Solution**: System-specific configs stored in `~/.config/nix/systems/`

**System types**:
- `desktop` - Full desktop with GPU acceleration
- `laptop` - Portable with power saving options
- `headless` - Server (no GUI)
- `minimal` - Basic setup, no window manager

**nixGL variants**:
- `none` - No wrapper, use system OpenGL
- `default` - Auto-detect GPU
- `nvidia` - Proprietary drivers (with version management)
- `bumblebee` - NVIDIA Optimus hybrid
- `intel` - Intel integrated graphics

### 4. Onboarding Wizard

**New script**: `scripts/onboard.sh`

Interactive setup for new systems:
```bash
./scripts/onboard.sh
```

Creates:
- `~/.config/nix/systems/<name>.nix`
- `~/.config/nix/active-system` (symlink)
- `~/.config/nix/.onboarded` (marker)

### 5. Pure Builds (No --impure)

**Problem**: Always needed `--impure` for system config detection

**Solution**: 
1. Configs now in known location: `~/.config/nix/active-system`
2. `allow-unfree = true` in `nix.conf`
3. Shell aliases for convenience:
   - `hm-switch` = `home-manager switch --flake ~/.config/nix`

## New Files

### Configuration Modules

| File | Purpose |
|------|---------|
| `home-manager/nvidia-config.nix` | NVIDIA management options |
| `home-manager/system-config.nix` | System type & nixGL variant options |
| `home-manager/nvidia-version.nix` | Version detection helpers |

### Scripts

| File | Purpose |
|------|---------|
| `scripts/nvidia-version-manager.sh` | Version management CLI |
| `scripts/onboard.sh` | Interactive onboarding wizard |

### Documentation

| File | Purpose |
|------|---------|
| `docs/R.0-Overview.md` | Repository overview |
| `docs/R.0.1-NVIDIA-Version-Management.md` | This file |

### Templates

| File | Purpose |
|------|---------|
| `home-manager/systems/laptop-template.nix` | Example laptop config |

## Configuration Options

### nvidiaManagement

```nix
{
  enableAutoDetection = true;      # Auto-detect on boot
  manualVersion = null;            # Override with "570.133.07"
  regenerateDesktopFile = true;    # Update hyprland.desktop
  desktopFilePath = /usr/share/wayland-sessions/hyprland.desktop;
  fallbackVersion = "570.133.07";
}
```

### systemConfig

```nix
{
  systemType = "laptop";           # desktop, laptop, headless, minimal
  nixGLVariant = "nvidia";         # none, default, nvidia, bumblebee, intel
  systemIdentifier = "laptop-x1";  # Unique name
}
```

## Migration from R.0

Old hardcoded version in home.nix:
```nix
nixGLNvidia = "${nixgl.packages.${pkgs.system}.nixGLNvidia}/bin/nixGLNvidia-570.133.07";
```

New dynamic approach:
```nix
nvidiaManagement.enableAutoDetection = true;
# OR
nvidiaManagement.manualVersion = "570.133.07";
```

## Systemd Integration

The `nvidia-version-manager` service:
- Runs before `graphical-session-pre.target`
- Detects NVIDIA version via nvidia-smi
- Updates `~/.config/nix/nvidia-version.conf`
- Regenerates hyprland.desktop if enabled

Prevents black screen after driver updates.

## Examples

### Desktop with auto-detect
```nix
{
  systemConfig.systemType = "desktop";
  systemConfig.nixGLVariant = "nvidia";
  nvidiaManagement.enableAutoDetection = true;
}
```

### Laptop with Intel (save battery)
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
  nvidiaManagement.manualVersion = "570.86.16";
}
```

### Headless server
```nix
{
  systemConfig.systemType = "headless";
  systemConfig.nixGLVariant = "none";
}
```

## CLI Reference

### onboarding
```bash
./scripts/onboard.sh [--force]           # Interactive setup
```

### nvidia-version-manager
```bash
./scripts/nvidia-version-manager.sh status           # Show config
./scripts/nvidia-version-manager.sh set-override    # Pin version
./scripts/nvidia-version-manager.sh clear-override  # Remove pin
./scripts/nvidia-version-manager.sh update          # Force update
./scripts/nvidia-version-manager.sh detect          # Detect only
```

### home-manager
```bash
# Pure (recommended after onboarding)
home-manager switch --flake ~/.config/nix

# Impure (fallback)
export NIXPKGS_ALLOW_UNFREE=1
home-manager switch --flake ~/.config/nix --impure
```

## Implementation Details

### Version Detection Priority
1. Manual override (if set)
2. Auto-detection (if enabled) via nvidia-smi
3. Fallback version

### Detection Methods (nvidia-version-manager.sh)
1. `nvidia-smi --query-gpu=driver_version` (most reliable)
2. `modinfo nvidia` (kernel module)
3. `/proc/driver/nvidia/version` (proc filesystem)
4. `dpkg -l | grep nvidia-driver` (package manager)

### Desktop File Generation
The script generates:
```
Exec=env WLR_RENDERER=vulkan GBM_BACKEND=nvidia-drm \
     __GLX_VENDOR_LIBRARY_NAME=nvidia \
     LIBVA_DRIVER_NAME=nvidia \
     XDG_SESSION_TYPE=wayland \
     LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm \
     NIXPKGS_ALLOW_UNFREE=1 \
     nixGLNvidia-${VERSION} Hyprland
```

## Troubleshooting

**Problem**: hyprland.desktop not updating

**Check**:
1. Service enabled: `systemctl --user status nvidia-version-manager`
2. Permissions: needs sudo to write to `/usr/share/wayland-sessions/`
3. Script exists: `ls ~/.config/nix/scripts/`

**Problem**: Wrong version detected

**Fix**:
```bash
./scripts/nvidia-version-manager.sh set-override $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | tr -d ' ')
```

**Problem**: Service not running

**Fix**:
```bash
home-manager switch --flake ~/.config/nix
systemctl --user enable nvidia-version-manager
systemctl --user start nvidia-version-manager
```

## Notes

- The systemd service runs with user permissions
- Desktop file update requires sudo or root access
- Version config is cached in `~/.config/nix/nvidia-version.conf`
- Manual override stored in `~/.config/nix/nvidia-version-override`
- No breaking changes - existing configs continue to work

---

*This revision makes the NVIDIA version management automatic and optional.*
