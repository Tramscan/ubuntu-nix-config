# nvidia-version.nix
# Helper module to determine which nixGL binary to use
# based on configuration (manual override or auto-detect)

{ config, pkgs, lib, nixgl, ... }:

let
  cfg = config.nvidiaManagement;

  # Function to get NVIDIA driver version from the system
  getNvidiaVersionFromSystem = pkgs.writeShellScript "get-nvidia-version" ''
    # Try nvidia-smi first (most reliable)
    if command -v nvidia-smi &> /dev/null; then
      version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 | tr -d '[:space:]')
      if [ -n "$version" ] && [ "$version" != "N/A" ]; then
        echo "$version"
        exit 0
      fi
    fi

    # Try modinfo as fallback
    if command -v modinfo &> /dev/null; then
      version=$(modinfo nvidia 2>/dev/null | grep '^version:' | head -n1 | awk '{print $2}' | tr -d '[:space:]')
      if [ -n "$version" ]; then
        echo "$version"
        exit 0
      fi
    fi

    # Try /proc/driver/nvidia/version
    if [ -f /proc/driver/nvidia/version ]; then
      version=$(cat /proc/driver/nvidia/version | grep "Kernel Module" | sed 's/.*Kernel Module  *\\([0-9.]*\\).*/\\1/' | tr -d '[:space:]')
      if [ -n "$version" ]; then
        echo "$version"
        exit 0
      fi
    fi

    # Could not detect
    echo ""
    exit 1
  '';

  # Determine which version to use
  nvidiaVersionInfo = rec {
    # Manual override takes highest priority
    manualVersion = cfg.manualVersion;

    # Default to fallback if set
    fallback = cfg.fallbackVersion;

    # The version that will be used
    effectiveVersion = if manualVersion != null
                       then manualVersion
                       else fallback;

    # Notification about version source
    versionSource = if manualVersion != null
                    then "manual-override"
                    else if cfg.enableAutoDetection
                    then "auto-detect"
                    else "fallback";
  };

  # Build the nixGL binary path
  nixGLNvidiaPath = let
    version = nvidiaVersionInfo.effectiveVersion;
    nixGLNvidia = nixgl.packages.${pkgs.system}.nixGLNvidia;
  in
    "${nixGLNvidia}/bin/nixGLNvidia-${version}";

  # Alternative: use the default nixGLNvidia (which tries to auto-detect)
  nixGLNvidiaDefault = "${nixgl.packages.${pkgs.system}.nixGLNvidia}/bin/nixGLNvidia";

  # Wrapper script that handles version detection at runtime
  nixGLNvidiaWrapper = pkgs.writeShellScriptBin "nixGLNvidia-managed" ''
    # This script is a wrapper that uses the configured NVIDIA version
    # It can be updated by running the nvidia-version-manager service

    NVIDIA_VERSION="${"@${"nvidiaVersionInfo.effectiveVersion}"@"}"
    NIXGL_BASE="${"@${"nixgl.packages.${pkgs.system}.nixGLNvidia}"@"}"

    # Check if we should try auto-detection
    if [ -z "$NVIDIA_VERSION" ] || [ "$NVIDIA_VERSION" = "auto" ]; then
      # Try to detect from system
      if command -v nvidia-smi &> /dev/null; then
        NVIDIA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 | tr -d '[:space:]')
      fi
    fi

    # If still no version, try the default nixGLNvidia
    if [ -z "$NVIDIA_VERSION" ]; then
      exec "${"@${"nixGLNvidiaDefault}"@"}" "$@"
    fi

    # Try the versioned binary first, fall back to default
    VERSIONED_BIN="${"@${"nixGLNvidiaPath}"@"}"
    if [ -x "$VERSIONED_BIN" ]; then
      exec "$VERSIONED_BIN" "$@"
    else
      echo "Warning: nixGLNvidia-$NVIDIA_VERSION not found, using default" >&2
      exec "${"@${"nixGLNvidiaDefault}"@"}" "$@"
    fi
  '';

in
{
  inherit nvidiaVersionInfo;
  inherit nixGLNvidiaPath;
  inherit nixGLNvidiaDefault;
  inherit nixGLNvidiaWrapper;

  # Convenience accessor for the nixGL command
  nixgl = rec {
    cmd = if cfg.manualVersion != null
          then nixGLNvidiaPath
          else if cfg.enableAutoDetection
          then nixGLNvidiaWrapper
          else nixGLNvidiaDefault;

    # Function to generate exec command string for systemd or .desktop
    mkExec = program: "${cmd} ${program}";
  };
}
