#!/usr/bin/env bash
# onboard-simple.sh - Fallback bash onboarding (no arrow keys)

set -euo pipefail

CONFIG_DIR="${HOME}/.config/nix"
SYSTEMS_DIR="${CONFIG_DIR}/systems"

header() {
    clear 2>/dev/null || true
    echo ""
    echo "=========================================="
    echo "     Just Enough Nix - Onboarding"
    echo "=========================================="
    echo ""
}

ask() {
    local prompt="$1"
    local default="${2:-}"
    local response
    
    echo -n "$prompt"
    [ -n "$default" ] && echo -n " [$default]"
    echo -n ": "
    
    # Read with timeout
    if ! IFS= read -r response </dev/tty 2>/dev/null; then
        response=""
    fi
    
    [ -z "$response" ] && [ -n "$default" ] && response="$default"
    echo "$response"
}

# Main
header

echo "This wizard will configure your system."
echo ""

# Step 1
name=$(ask "Step 1/4: System name (e.g., laptop-x1)" "${HOSTNAME:-my-system}")
[ -z "$name" ] && name="my-system"

# Step 2
header
echo "Step 2/4: System Type"
echo "1) desktop - Full GPU acceleration"
echo "2) laptop  - Portable with power saving"
echo "3) headless - Server (no GUI)"
echo "4) minimal - Basic setup"
echo ""

type_choice=""
while [[ ! "$type_choice" =~ ^[1-4]$ ]]; do
    type_choice=$(ask "Select (1-4)" "2")
    [[ ! "$type_choice" =~ ^[1-4]$ ]] && echo "Please enter 1-4"
done

types=(desktop laptop headless minimal)
sys_type="${types[$((type_choice-1))]}"

# Step 3
header
echo "Step 3/4: Graphics Configuration"
echo "1) none      - No wrapper"
echo "2) default   - Auto-detect"
echo "3) nvidia    - NVIDIA proprietary"
echo "4) bumblebee - NVIDIA Optimus"
echo "5) intel     - Intel integrated"
echo ""

nixgl_choice=""
while [[ ! "$nixgl_choice" =~ ^[1-5]$ ]]; do
    nixgl_choice=$(ask "Select (1-5)" "3")
    [[ ! "$nixgl_choice" =~ ^[1-5]$ ]] && echo "Please enter 1-5"
done

nixgl_opts=(none default nvidia bumblebee intel)
nixgl="${nixgl_opts[$((nixgl_choice-1))]}"

# Step 4 (NVIDIA only)
nv_auto="true"
nv_manual="null"

if [ "$nixgl" = "nvidia" ]; then
    header
    echo "Step 4/4: NVIDIA Version Management"
    echo ""
    echo "Enable auto-detection?"
    echo "1) Yes - Auto-detect (recommended)"
    echo "2) No  - Pin specific version"
    echo ""
    
    auto_choice=$(ask "Select (1-2)" "1")
    if [ "$auto_choice" = "2" ]; then
        nv_auto="false"
        ver=$(ask "Enter version (e.g., 570.133.07)" "570.133.07")
        nv_manual="\"$ver\""
        mkdir -p "$CONFIG_DIR"
        echo "$ver" > "${CONFIG_DIR}/nvidia-version-override"
    fi
fi

# Write config
header
mkdir -p "$SYSTEMS_DIR"

cat > "${SYSTEMS_DIR}/${name}.nix" << EOF
# System: $name
{ config, lib, ... }: {
  systemConfig = {
    systemType = "$sys_type";
    nixGLVariant = "$nixgl";
    systemIdentifier = "$name";
  };
  nvidiaManagement = {
    enableAutoDetection = $nv_auto;
    manualVersion = $nv_manual;
    regenerateDesktopFile = true;
    fallbackVersion = "570.133.07";
  };
}
EOF

echo "$name" > "${CONFIG_DIR}/active-system"

echo "✓ Configuration complete!"
echo ""
echo "System: $name"
echo "Type:   $sys_type"
echo "nixGL:  $nixgl"
echo ""
echo "Next: home-manager switch --flake ~/.config/nix"
