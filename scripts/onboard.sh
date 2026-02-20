#!/usr/bin/env bash
# onboard.sh - Interactive onboarding for ubuntu-nix-config

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CONFIG_DIR="${HOME}/.config/nix"
SYSTEMS_DIR="${CONFIG_DIR}/systems"
ONBOARD_STATE="${CONFIG_DIR}/.onboarded"

ask() {
    local prompt="$1"
    local default="${2:-}"
    local response=""
    
    echo -ne "${BOLD}${prompt}${NC}"
    if [ -n "$default" ]; then
        echo -ne " [${YELLOW}${default}${NC}]"
    fi
    echo -ne ": "
    
    # Read with timeout and error handling
    if IFS= read -r response 2>/dev/null; then
        : # success
    else
        response=""
    fi
    
    # Use default if empty
    if [ -z "$response" ] && [ -n "$default" ]; then
        response="$default"
    fi
    
    echo "$response"
}

ask_yn() {
    local prompt="$1"
    local default="${2:-y}"
    local response=""
    
    while true; do
        echo -ne "${BOLD}${prompt}${NC}"
        if [ "$default" = "y" ]; then
            echo -ne " [${GREEN}Y${NC}/n]"
        else
            echo -ne " [y/${RED}N${NC}]"
        fi
        echo -ne ": "
        
        IFS= read -r response 2>/dev/null || response=""
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
        
        if [ -z "$response" ]; then
            response="$default"
        fi
        
        case "$response" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo -e "${RED}Please answer yes or no${NC}" ;;
        esac
    done
}

detect_gpu() {
    if command -v nvidia-smi &>/dev/null; then
        local v=""
        v=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 | tr -d '[:space:]' || echo "")
        if [ -n "$v" ] && [ "$v" != "N/A" ]; then
            echo "nvidia:$v"
            return
        fi
    fi
    
    if command -v lspci &>/dev/null; then
        if lspci 2>/dev/null | grep -qi intel; then
            echo "intel"
            return
        fi
        if lspci 2>/dev/null | grep -qi amd; then
            echo "amd"
            return
        fi
    fi
    
    echo "unknown"
}

echo -e "${CYAN}"
cat << 'HDR'
 _   _           _                  _   _      _ _
| | | | ___   __| | ___  | (_) _ __     | |_ __ _| | _____  ___
| |_| |/ _ \ / _` |/ _ \ | | | '_ \    | __/ _` | |/ / _ \/ __|
|  _  | (_) | (_| |  __/ | | | | | |  | || (_| |   <  __/\__ \
|_| |_|\___/ \__,_|\___| |_|_|_| |_|   \__\__,_|_|\_\___||___/

                Onboarding
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
if [ -z "$SID" ]; then
    SID="my-system"
fi

# Step 2: System Type
echo ""
echo -e "${BLUE}Step 2/4: System Type${NC}"
echo "  1. desktop - Full desktop with GPU acceleration"
echo "  2. laptop  - Portable with power saving"
echo "  3. headless - Server (no GUI)"
echo "  4. minimal - Basic setup (no window manager)"
echo ""

STYPE_CHOICE=""
while [[ ! "$STYPE_CHOICE" =~ ^[1-4]$ ]]; do
    STYPE_CHOICE=$(ask "Select type" "2")
    if [[ ! "$STYPE_CHOICE" =~ ^[1-4]$ ]]; then
        echo -e "${RED}Please enter 1-4${NC}"
    fi
done

STYPES=(desktop laptop headless minimal)
STYPE="${STYPES[$((STYPE_CHOICE-1))]}"

# Step 3: Graphics Configuration
echo ""
echo -e "${BLUE}Step 3/4: Graphics Configuration${NC}"

GPU_DETECT=$(detect_gpu)
DETECTED=""
NV_VER=""

if [[ "$GPU_DETECT" =~ ^nvidia ]]; then
    DETECTED="nvidia"
    NV_VER="${GPU_DETECT#nvidia:}"
else
    DETECTED="$GPU_DETECT"
fi

if [ "$STYPE" = "headless" ]; then
    echo "${GREEN}Headless system - skipping GPU detection${NC}"
else
    echo ""
    echo "  1. none      - No wrapper (use system OpenGL)"
    echo "  2. default   - Auto-detect GPU type"
    echo "  3. nvidia    - NVIDIA proprietary drivers"
    echo "  4. bumblebee - NVIDIA Optimus (hybrid graphics)"
    echo "  5. intel     - Intel integrated graphics"
    echo ""
    
    DFT=2
    if [ "$DETECTED" = "nvidia" ]; then
        DFT=3
        echo -e "${YELLOW}Detected NVIDIA GPU (driver: ${NV_VER:-unknown})${NC}"
    elif [ "$DETECTED" = "intel" ]; then
        DFT=5
        echo -e "${YELLOW}Detected Intel GPU${NC}"
    fi
    
    NG_CHOICE=""
    while [[ ! "$NG_CHOICE" =~ ^[1-5]$ ]]; do
        NG_CHOICE=$(ask "Select variant" "$DFT")
        if [[ ! "$NG_CHOICE" =~ ^[1-5]$ ]]; then
            echo -e "${RED}Please enter 1-5${NC}"
        fi
    done
    
    NGL_VARIANTS=(none default nvidia bumblebee intel)
    NGL="${NGL_VARIANTS[$((NG_CHOICE-1))]}"
fi

# Step 4: NVIDIA-specific options
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
        if [ -n "${NV_VER:-}" ]; then
            echo -e "${GREEN}Current driver: ${NV_VER}${NC}"
        fi
    else
        NV_AUTO="false"
        ENABLE_MGR="false"
        MN=$(ask "Pin to version" "${NV_VER:-570.133.07}")
        if [[ ! "$MN" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
            MN="570.133.07"
        fi
        NV_MANUAL="\"$MN\""
        mkdir -p "$CONFIG_DIR"
        echo "$MN" > "${CONFIG_DIR}/nvidia-version-override"
        echo -e "${YELLOW}Pinned to: $MN${NC}"
    fi
fi

# Write configuration
echo ""
echo -e "${GREEN}Writing configuration...${NC}"

cat > "${SYSTEMS_DIR}/${SID}.nix" << EOF
# System config for: $SID
{ config, lib, ... }: {
  systemConfig = {
    systemType = "$STYPE";
    nixGLVariant = "$NGL";
    systemIdentifier = "$SID";
  };
  nvidiaManagement = {
    enableAutoDetection = $NV_AUTO;
    manualVersion = $NV_MANUAL;
    regenerateDesktopFile = true;
    fallbackVersion = "570.133.07";
  };
}
EOF

echo "$SID" > "${CONFIG_DIR}/active-system"

cat > "$ONBOARD_STATE" << EOF
ONBOARDED=true
SYSTEM_ID=$SID
SYSTEM_TYPE=$STYPE
NIXGL=$NGL
NV_AUTO=$NV_AUTO
DATE=$(date -Iseconds)
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
 