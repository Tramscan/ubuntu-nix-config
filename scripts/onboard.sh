#!/usr/bin/env bash
# onboard.sh - Interactive onboarding for ubuntu-nix-config

set -euo pipefail

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

CONFIG_DIR="${HOME}/.config/nix"
SYSTEMS_DIR="${CONFIG_DIR}/systems"
ONBOARD_STATE="${CONFIG_DIR}/.onboarded"

ask() {
    local p="$1" d="${2:-}"
    echo -ne "${BOLD}${p}${NC}"
    [ -n "$d" ] && echo -ne " [${YELLOW}${d}${NC}]"
    echo -ne ": "
    read -r r
    [ -z "$r" ] && r="$d"
    echo "$r"
}

ask_yn() {
    local p="$1" d="${2:-y}"
    while true; do
        echo -ne "${BOLD}${p}${NC} ["
        [ "$d" = "y" ] && echo -ne "${GREEN}Y${NC}/n]" || echo -ne "y/${RED}N${NC}]"
        echo -ne ": "
        read -r r
        r=$(echo "$r" | tr '[:upper:]' '[:lower:]')
        [ -z "$r" ] && r="$d"
        case "$r" in y|yes) return 0 ;; n|no) return 1 ;; *) echo -e "${RED}yes/no${NC}" ;; esac
    done
}

detect_gpu() {
    if command -v nvidia-smi &>/dev/null; then
        local v=""
        v=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 | tr -d '[:space:]' || echo "")
        [ -n "$v" ] && [ "$v" != "N/A" ] && echo "nvidia:$v" && return
    fi
    if command -v lspci &>/dev/null; then
        lspci | grep -qi intel && echo "intel" && return
        lspci | grep -qi amd && echo "amd" && return
    fi
    echo "unknown"
}

echo -e "${CYAN}"
cat << 'HDR'
   _    _           _                  _   _      _ _
  / \  | | ___ _ __| |_ ___  _ __ __ _| \ | | ___| | | __ _
 / _ \ | |/ _ \ '__| __/ _ \| '__/ _` |  \| |/ _ \ | |/ _` |
/ ___ \| |  __/ |  | || (_) | | | (_| | |\ |  __/ | | (_| |
/_/   \_\_|\___|_|   \__\___/|_|  \__, |_| \_|\___|_|_|\__,_|
                                  |___/        Onboarding
HDR
echo -e "${NC}"

# Parse args
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=true ;;
        --help|-h) echo "Usage: $0 [--force]"; exit 0 ;;
    esac
done

# Check already onboarded
if [ -f "$ONBOARD_STATE" ] && [ "$FORCE" = "false" ]; then
    echo -e "${YELLOW}Already onboarded.${NC}"
    if ! ask_yn "Run again?" "n"; then
        echo -e "${GREEN}Skipping (use --force to override)${NC}"
        exit 0
    fi
fi

mkdir -p "$SYSTEMS_DIR"

echo ""
echo -e "${BOLD}Let's configure your system!${NC}"
echo ""

# Step 1: System Identity
echo -e "${BLUE}Step 1/4: System Identity${NC}"
echo "Examples: laptop-x1, work-dell, gaming-rig"
SID=$(ask "System name" "${HOSTNAME:-my-system}")
[ -z "$SID" ] && SID="my-system"

# Step 2: System Type
echo ""
echo -e "${BLUE}Step 2/4: System Type${NC}"
echo "  1. desktop  - Full desktop with GPU acceleration"
echo "  2. laptop   - Portable with power saving"
echo "  3. headless - Server (no GUI)"
echo "  4. minimal  - Basic setup (no window manager)"
echo ""
STYPE_CHOICE=$(ask "Select type" "2")
while [[ ! "$STYPE_CHOICE" =~ ^[1-4]$ ]]; do
    echo -e "${RED}Please enter 1-4${NC}"
    STYPE_CHOICE=$(ask "Select type")
done
STYPES=(desktop laptop headless minimal)
STYPE="${STYPES[$((STYPE_CHOICE-1))]}"

# Step 3: Graphics Configuration
echo ""
echo -e "${BLUE}Step 3/4: Graphics Configuration${NC}"

# Auto-detect GPU
GPU_DETECT=$(detect_gpu)
[[ "$GPU_DETECT" =~ ^nvidia ]] && DETECTED="nvidia" && NV_VER="${GPU_DETECT#nvidia:}" || DETECTED="${GPU_DETECT}"

[ "$STYPE" = "headless" ] && echo "${GREEN}Headless system - skipping GPU detection${NC}" || echo ""

if [ "$STYPE" != "headless" ]; then
    echo "  1. none      - No nixGL wrapper (use system OpenGL)"
    echo "  2. default   - Auto-detect GPU"
    echo "  3. nvidia    - NVIDIA proprietary drivers"
    echo "  4. bumblebee - NVIDIA Optimus (hybrid)"
    echo "  5. intel     - Intel integrated"
    echo ""

    # Default based on detection
    DFT=2
    if [ "$DETECTED" = "nvidia" ]; then
        DFT=3
        echo -e "${YELLOW}Detected NVIDIA GPU (driver: ${NV_VER:-unknown})${NC}"
    elif [ "$DETECTED" = "intel" ]; then
        DFT=5
        echo -e "${YELLOW}Detected Intel GPU${NC}"
    fi

    NG_CHOICE=$(ask "Select variant" "$DFT")
    while [[ ! "$NG_CHOICE" =~ ^[1-5]$ ]]; do
        echo -e "${RED}Please enter 1-5${NC}"
        NG_CHOICE=$(ask "Select variant"
    done
    NGL_VARIANTS=(none default nvidia bumblebee intel)
    NGL="${NGL_VARIANTS[$((NG_CHOICE-1))]}"
else
    NGL="none"
fi

# Step 4: NVIDIA Options (if applicable)
NV_AUTO="false"
NV_MANUAL="null"
ENABLE_MGR="false"

if [ "$NGL" = "nvidia" ]; then
    echo ""
    echo -e "${BLUE}Step 4/4: NVIDIA Version Management${NC}"
    echo ""

    if ask_yn "Enable auto-detection at boot?" "y"; then
        NV_AUTO="true"
        ENABLE_MGR="true"
        [ -n "${NV_VER:-}" ] && echo -e "${GREEN}Current driver: ${NV_VER}${NC}"
    else
        NV_AUTO="false"
        ENABLE_MGR="false"
        MN=$(ask "Pin to version" "${NV_VER:-570.133.07}")
        [[ "$MN" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || MN="570.133.07"
        NV_MANUAL="\"${MN}\""
        mkdir -p "$CONFIG_DIR"
        echo "$MN" > "${CONFIG_DIR}/nvidia-version-override"
        echo -e "${YELLOW}Pinned to: ${MN}${NC}"
    fi
fi

# Perform onboarding
echo ""
echo -e "${GREEN}Writing configuration...${NC}"

# Write system config
cat > "${SYSTEMS_DIR}/${SID}.nix" << EOF
# System: $SID
{ config, lib, ... }:
{
  systemConfig = {
    systemType = "$STYPE";
    nixGLVariant = "$NGL";
    systemIdentifier = "$SID";
  };

  nvidiaManagement = {
    enableAutoDetection = $NV_AUTO;
    manualVersion = $NV_MANUAL;
    regenerateDesktopFile = ${NGL == "nvidia" && NGL == "nvidia"};
    fallbackVersion = "570.133.07";
  };
}
EOF

# Set as active
echo "$SID" > "${CONFIG_DIR}/active-system"

# Mark as onboarded
cat > "$ONBOARD_STATE" << EOF
ONBOARDED=true
SYSTEM_ID=$SID
DATE=$(date -Iseconds)
NIXGL=$NGL
NV_AUTO=$NV_AUTO
EOF

echo ""
echo -e "${GREEN}✓ ONBOARDING COMPLETE${NC}"
echo ""
echo "System:    $SID"
echo "Type:      $STYPE"
echo "nixGL:     $NGL"
[ "$NGL" = "nvidia" ] && echo "Auto-detect: $NV_AUTO"
echo ""
echo "Config:    ~/.config/nix/systems/${SID}.nix"
echo ""
echo "Next:"
echo "  1. home-manager switch --flake ~/.config/nix"
echo "  2. nvidia-version-manager.sh status"
echo ""
ONBOARD_EOF