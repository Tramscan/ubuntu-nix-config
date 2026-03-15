{ config, pkgs, lib, ... }:

let
  # Determine which nixGL wrapper to use from system config
  nixGLWrapper = config.systemConfig.nixGLWrapper or null;
  useNixGL = nixGLWrapper != null && nixGLWrapper != "";

  # Create wrapped Vesktop with proper environment
  vesktopWrapped = pkgs.writeShellScriptBin "vesktop" ''
    #!/usr/bin/env bash
    # Vesktop wrapper with nixGL and Wayland/NVIDIA fixes
    
    export NIXOS_OZONE_WL="1"
    export ELECTRON_ENABLE_SECURITY_WARNINGS="false"
    
    ${lib.optionalString (config.systemConfig.nixGLVariant == "nvidia") ''
    # NVIDIA-specific settings
    export GBM_BACKEND="nvidia-drm"
    export __GLX_VENDOR_LIBRARY_NAME="nvidia"
    export MESA_LOADER_DRIVER_OVERRIDE="nvidia"
    export LIBVA_DRIVER_NAME="nvidia"
    ''}
    
    # PipeWire for screen sharing
    export PIPEWIRE_RUNTIME_DIR="/run/user/$(id - u)"
    
    # Allow unfree packages
    export NIXPKGS_ALLOW_UNFREE="1"
    
    # Additional Electron/Chromium stability flags
    export ELECTRON_DISABLE_GPU="0"
    export ELECTRON_FORCE_USE_WEBGL="1"
    
    # Debug output (remove after testing)
    echo "[vesktop-wrapper] nixGL: ${nixGLWrapper}"
    echo "[vesktop-wrapper] Variant: ${config.systemConfig.nixGLVariant}"
    
    # Launch with nixGL
    if [ -x "${nixGLWrapper}" ]; then
      exec ${nixGLWrapper} ${pkgs.vesktop}/bin/vesktop "$@"
    else
      echo "[vesktop-wrapper] nixGL wrapper not found, running unwrapped"
      exec ${pkgs.vesktop}/bin/vesktop "$@"
    fi
  '';

  # Create a "safe mode" wrapper too
  vesktopSafe = pkgs.writeShellScriptBin "vesktop-safe" ''
    #!/usr/bin/env bash
    # Vesktop safe mode (disable GPU acceleration)
    
    export NIXOS_OZONE_WL="1"
    
    echo "[vesktop-safe] Starting in safe mode (no GPU)"
    
    exec ${pkgs.vesktop}/bin/vesktop --disable-gpu --no-sandbox "$@"
  '';

in
{
  # Installation
  home.packages = with pkgs; [
    (if useNixGL then vesktopWrapped else pkgs.vesktop)
    vesktopSafe
  ];

  # Desktop entry - use the wrapper
  xdg.desktopEntries = lib.mkIf useNixGL {
    vesktop = {
      name = "Vesktop";
      genericName = "Discord Client";
      exec = "vesktop %U";
      icon = "vesktop";
      type = "Application";
      categories = [ "Network" "Chat" ];
      startupNotify = true;
    };
  };

  # Programs configuration (only if not using wrapper)
  programs.vesktop = lib.mkIf (!useNixGL) {
    settings = {
      hardwareAcceleration = true;
    };
    vencord.settings = {
      autoUpdate = true;
      plugins = {
        FakeNitro.enabled = true;
        BetterSettings.enabled = true;
        SpotifyControls.enabled = true;
      };
    };
  };

  # Shell alias for convenience
  # NOTE: Commented out to avoid conflict with home.nix shellAliases
  # home.shellAliases = lib.mkIf useNixGL {
  #   "vesktop-nogpu" = "vesktop --disable-gpu";
  # };
}
