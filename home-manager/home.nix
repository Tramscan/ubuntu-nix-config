{ config, pkgs, lib, inputs, nixgl, ... }:

let
  # Detect if this is NVIDIA system
  isNvidia = config.systemConfig.nixGLVariant == "nvidia";
  
  # Get NVIDIA version (manual overrides auto)
  nvidiaVersion = 
    if config.nvidiaManagement.manualVersion != null 
    then config.nvidiaManagement.manualVersion
    else if config.nvidiaManagement.enableAutoDetection
    then config.nvidiaManagement.fallbackVersion
    else "570.133.07";

  # Build nixGL command based on variant
  nixGLCmd = let
    variant = config.systemConfig.nixGLVariant;
    base = nixgl.packages.${pkgs.system};
  in
    if variant == "none" then null
    else if variant == "nvidia" then "${base.nixGLNvidia}/bin/nixGLNvidia-${nvidiaVersion}"
    else if variant == "default" then "${base.nixGLDefault}/bin/nixGLDefault"
    else if variant == "bumblebee" then "${base.nixGLNvidiaBumblebee}/bin/nixGLNvidiaBumblebee"
    else if variant == "intel" then "${base.nixGLIntel}/bin/nixGLIntel"
    else null;

  wrappedSteam = pkgs.writeShellScriptBin "steam" ''
    LD_LIBRARY_PATH= exec /usr/bin/steam "$@"
  '';

in
{
  imports = [
    ./nvidia-config.nix
    ./system-config.nix
    ./apps/i3
    ./apps/nixvim
    ./apps/alacritty
    ./apps/hyprland
    ./apps/waybar
    ./apps/firefox
    ./apps/vesktop
    ./apps/kicad
  ];

  # ============================================
  # BASIC SETTINGS
  # ============================================
  home.username = "nick";
  home.homeDirectory = "/home/nick";
  home.stateVersion = "24.05";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (pkg: true);

  # ============================================
  # DEFAULT CONFIGURATION (override in system-specific files)
  # ============================================
  
  # A. Auto-detect NVIDIA drivers? Set to false to use manual version
  nvidiaManagement.enableAutoDetection = lib.mkDefault true;
  
  # B. Manual version override (null = use auto-detect)
  # Set to "570.133.07" to pin that version
  nvidiaManagement.manualVersion = lib.mkDefault null;
  
  nvidiaManagement.regenerateDesktopFile = lib.mkDefault true;
  nvidiaManagement.fallbackVersion = lib.mkDefault "570.133.07";

  # System type and nixGL variant
  systemConfig.systemType = lib.mkDefault "desktop";
  systemConfig.nixGLVariant = lib.mkDefault "nvidia";

  # ============================================
  # NVIDIA VERSION DETECTION SERVICE
  # Runs before display manager to detect/driver updates
  # ============================================
  systemd.user.services.nvidia-version-manager = lib.mkIf isNvidia {
    Unit = {
      Description = "NVIDIA Driver Version Manager";
      Before = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = let
        script = pkgs.writeShellScript "nvidia-version-service" ''
          CONFIG="$HOME/.config/nix"
          mkdir -p "$CONFIG"
          
          DETECTED=""
          if command -v nvidia-smi &>/dev/null; then
            DETECTED=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 | tr -d '[:space:]')
          fi
          [ -z "$DETECTED" ] && DETECTED="${nvidiaVersion}"
          
          echo "[nvidia-version] Version: $DETECTED"
          echo "NVIDIA_VERSION=$DETECTED" > "$CONFIG/nvidia-version.conf"
          
          # Update .desktop file if enabled and running as user with sudo
          DESKTOP="/usr/share/wayland-sessions/hyprland.desktop"
          if command -v sudo &>/dev/null && [ -d "$(dirname $DESKTOP)" ]; then
            cat > /tmp/hyprland.desktop.new << DESKTOP_EOF
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=env WLR_RENDERER=vulkan GBM_BACKEND=nvidia-drm __GLX_VENDOR_LIBRARY_NAME=nvidia LIBVA_DRIVER_NAME=nvidia XDG_SESSION_TYPE=wayland LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm NIXPKGS_ALLOW_UNFREE=1 nixGLNvidia-$DETECTED Hyprland
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;
DESKTOP_EOF
            sudo mv /tmp/hyprland.desktop.new "$DESKTOP": 2>/dev/null || true
          fi
        '';
      in "${script}";
      RemainAfterExit = true;
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # ============================================
  # SERVICES & PACKAGES
  # ============================================
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
  };

  systemd.user.services.sunshine = lib.mkIf isNvidia {
    Unit = {
      Description = "Sunshine Game Stream Host";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.mkIf (nixGLCmd != null) 
        "${nixGLCmd} ${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  home.packages = with pkgs; [
    neofetch
    picom
    waybar
    protonup-qt
    mujoco
    freecad
    mesa-demos
    alacritty
    gh
    pavucontrol
    zenith-nvidia
    obsidian
    libva
    egl-wayland
    wayland
    wayland-protocols
    libglvnd
    xwayland
    nixgl.packages.${pkgs.system}.nixGLNvidia
    nixgl.packages.${pkgs.system}.nixGLDefault
    nixgl.packages.${pkgs.system}.nixGLNvidiaBumblebee
    nixgl.packages.${pkgs.system}.nixGLIntel
    wofi
    wrappedSteam
    qbittorrent
    sunshine
    pipewire
    nodejs_24
  ];

  home.sessionVariables = {
    SUDO_EDITOR = "nvim";
    SYSTEMD_EDITOR = "nvim";
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "alacritty";
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    NIXPKGS_ALLOW_UNFREE = 1;
    NIXOS_OZONE_WL = "1";
  };

  programs.home-manager.enable = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" "auto-allocate-uids"];
      auto-optimise-store = true;
      auto-allocate-uid = true;
      max-jobs = "auto";
      trusted-users = [ "nick" ];
    };
    package = pkgs.nix;
  };

  programs.kitty.enable = true;
  programs.alacritty = { enable = true; };
}
