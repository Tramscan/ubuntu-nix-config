#!/usr/bin/env bash
# nvidia-version-manager.sh
# Managed NVIDIA driver version configuration for nixGL
# This script detects the current NVIDIA driver version and:
# 1. Updates the cached version file (~/.config/nix/nvidia-version.conf)
# 2. Regenerates the hyprland.desktop file with the correct nixGL version
# 3. Can be run manually or as a systemd service before display-manager

set -euo pipefail

# Configuration file location
CONFIG_DIR="${HOME}/.config/nix"
VERSION_FILE="${CONFIG_DIR}/nvidia-version.conf"
OVERRIDE_FILE="${CONFIG_DIR}/nvidia-version-override"
DEFAULT_VERSION="570.133.07"

# User configuration (can be adjusted via environment)
DESKTOP_FILE_PATH="${HYPRLAND_DESKTOP_FILE:-/usr/share/wayland-sessions/hyprland.desktop}"
REGENERATE_DESKTOP="${HYPRLAND_REGENERATE_DESKTOP:-true}"
AUTO_DETECTION="${HYPRLAND_AUTO_DETECT:-true}"

# Logging function
log() {
    echo "[nvidia-version-manager] $(date '+%Y-%m-%d %H:%M:%S'): $*"
}

# Detect NVIDIA driver version from the system
detect_nvidia_version() {
    local version=""

    # Method 1: nvidia-smi (most reliable for installed drivers)
    if command -v nvidia-smi &>/dev/null; then
        version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 | tr -d '[:space:]')
        if [ -n "$version" ] && [ "$version" != "N/A" ]; then
            log "Detected via nvidia-smi: $version"
            echo "$version"
            return 0
        fi
    fi

    # Method 2: modinfo
    if command -v modinfo &>/dev/null; then
        version=$(modinfo nvidia 2>/dev/null | grep '^version:' | head -n1 | awk '{print $2}' | tr -d '[:space:]')
        if [ -n "$version" ]; then
            log "Detected via modinfo: $version"
            echo "$version"
            return 0
        fi
    fi

    # Method 3: /proc/driver/nvidia/version
    if [ -f /proc/driver/nvidia/version ]; then
        version=$(grep "Kernel Module" /proc/driver/nvidia/version 2>/dev/null | sed 's/.*Kernel Module  *\([0-9.]*\).*/\1/' | tr -d '[:space:]')
        if [ -n "$version" ]; then
            log "Detected via /proc/driver/nvidia/version: $version"
            echo "$version"
            return 0
        fi
    fi

    # Method 4: dpkg/apt (for Ubuntu systems)
    if command -v dpkg &>/dev/null; then
        version=$(dpkg -l | grep -E '^ii.*nvidia-driver-' | head -n1 | awk '{print $3}' | cut -d'-' -f1 | tr -d '[:space:]')
        if [ -n "$version" ]; then
            log "Detected via dpkg: $version"
            echo "$version"
            return 0
        fi
    fi

    log "Could not detect NVIDIA driver version"
    return 1
}

# Check for manual override
check_manual_override() {
    if [ -f "$OVERRIDE_FILE" ]; then
        local override_version
        override_version=$(cat "$OVERRIDE_FILE" | tr -d '[:space:]')
        if [ -n "$override_version" ]; then
            log "Manual override active: $override_version"
            echo "$override_version"
            return 0
        fi
    fi
    return 1
}

# Get the version to use (manual override takes priority)
get_effective_version() {
    # Check manual override first
    if check_manual_override >/dev/null 2>&1; then
        check_manual_override
        return 0
    fi

    # Try auto-detection if enabled
    if [ "${AUTO_DETECTION}" = "true" ]; then
        if detect_nvidia_version >/dev/null 2>&1; then
            detect_nvidia_version
            return 0
        fi
    fi

    # Fall back to default
    log "Using fallback version: $DEFAULT_VERSION"
    echo "$DEFAULT_VERSION"
}

# Generate hyprland.desktop file
generate_desktop_file() {
    local version="$1"
    local nixgl_bin="nixGLNvidia"

    if [ -n "$version" ]; then
        nixgl_bin="nixGLNvidia-$version"
    fi

    log "Generating desktop file with nixGL: $nixgl_bin"

    local desktop_content="[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=env WLR_RENDERER=vulkan GBM_BACKEND=nvidia-drm __GLX_VENDOR_LIBRARY_NAME=nvidia LIBVA_DRIVER_NAME=nvidia XDG_SESSION_TYPE=wayland LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm NIXPKGS_ALLOW_UNFREE=1 $nixgl_bin Hyprland
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;"

    # Determine where to write the file
    local target_file="$DESKTOP_FILE_PATH"
    local temp_file="/tmp/hyprland.desktop.tmp.$$"

    # Create the content in a temp file first
    echo "$desktop_content" > "$temp_file"

    # Check if we can write to the target location
    if [ -w "$(dirname "$target_file")" ]; then
        mv "$temp_file" "$target_file"
        log "Wrote desktop file to: $target_file"
    elif command -v sudo &>/dev/null; then
        # Try with sudo
        if sudo mv "$temp_file" "$target_file" 2>/dev/null; then
            log "Wrote desktop file to: $target_file (with sudo)"
        else
            log "ERROR: Could not write to $target_file even with sudo"
            rm -f "$temp_file"
            return 1
        fi
    else
        log "ERROR: Cannot write to $target_file and sudo not available"
        rm -f "$temp_file"
        return 1
    fi

    return 0
}

# Write version configuration for nix to read
write_version_config() {
    local version="$1"
    local manual="$2"

    mkdir -p "$CONFIG_DIR"

    cat > "$VERSION_FILE" << EOF
# NVIDIA Driver Version Configuration
# Generated by nvidia-version-manager
# Do not edit manually - use ~/.config/nix/nvidia-version-override instead

NVIDIA_VERSION="${version}"
MANUAL_OVERRIDE="${manual}"
GENERATED_AT="$(date -Iseconds)"
AUTO_DETECTION="${AUTO_DETECTION}"
EOF

    log "Wrote version config: $VERSION_FILE (version: $version, manual: $manual)"
}

# Show current status
show_status() {
    echo "=== NVIDIA Version Manager Status ==="
    echo ""
    echo "Configuration files:"
    echo "  Version file: $VERSION_FILE"
    echo "  Override file: $OVERRIDE_FILE"
    echo ""
    echo "Current settings:"
    echo "  Auto-detection: $AUTO_DETECTION"
    echo "  Regenerate desktop: $REGENERATE_DESKTOP"
    echo "  Desktop file path: $DESKTOP_FILE_PATH"
    echo ""

    if [ -f "$OVERRIDE_FILE" ]; then
        echo "Manual override: $(cat "$OVERRIDE_FILE" | tr -d '[:space:]') (ACTIVE)"
    else
        echo "Manual override: (none)"
    fi

    local detected=""
    if detected=$(detect_nvidia_version 2>/dev/null); then
        echo "Detected version: $detected"
    else
        echo "Detected version: (could not detect)"
    fi

    if [ -f "$VERSION_FILE" ]; then
        echo ""
        echo "Cached configuration:"
        cat "$VERSION_FILE" | grep -v '^#' | sed 's/^/  /'
    fi
}

# Parse arguments
MODE="${1:-update}"

# Main command handler
case "$MODE" in
    update|-u|--update)
        log "Starting NVIDIA version update process..."

        # Ensure config directory exists
        mkdir -p "$CONFIG_DIR"

        # Determine effective version
        local version=""
        local is_manual="false"

        # Check for override first
        if check_manual_override >/dev/null 2>&1; then
            version=$(check_manual_override)
            is_manual="true"
        else
            # Try auto-detection
            if [ "${AUTO_DETECTION}" = "true" ]; then
                if detect_nvidia_version >/dev/null 2>&1; then
                    version=$(detect_nvidia_version)
                fi
            fi

            # Fall back to default if needed
            if [ -z "$version" ]; then
                version="$DEFAULT_VERSION"
            fi
        fi

