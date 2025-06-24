{ config, pkgs, lib, inputs, nixgl, ...}:

let
  # Use the pre-configured versioned wrapper
#  nvidiaVersion = "535.230.02"; # Replace with your actual version
#  nixGLNvidiaBin = "${nixgl.packages.${pkgs.system}.nixGLNvidia}/bin/nixGLNvidia";
#  hyprlandBin = "${pkgs.hyprland}/bin/Hyprland";
  #hyprlandWrapper = pkgs.writeShellScriptBin "hyprland-wrapped" ''
  #  export NVIDIA_DRIVER_VERSION=${nvidiaVersion}
  #  export GBM_BACKEND=nvidia-drm
  #  export LIBVA_DRIVER_NAME=nvidia
  #  export __GLX_VENDOR_LIBRARY_NAME=nvidia
  #  exec ${nixGLNvidiaBin} ${hyprlandBin} "$@"
  #'';
  hyprlandWrapper = pkgs.writeShellScriptBin "hyprland-nixglhost" '' 
    exec nix-gl-host Hyprland "$@"
    '';
in
{
  home.packages = [ hyprlandWrapper ];
  home.sessionVariables = {
      WLR_RENDERER = "vulkan";
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # It's also often helpful to include these for broader Wayland compatibility
      NIXOS_OZONE_WL = "1";      # For Electron apps (VSCode, Discord, etc.)
      QT_QPA_PLATFORM = "wayland"; # For Qt apps
      GDK_BACKEND = "wayland";     # For GTK apps
      XDG_CURRENT_DESKTOP = "Hyprland"; # Helps some apps recognize the DE
      XDG_SESSION_TYPE = "wayland"; # Indicates Wayland session
      XDG_SESSION_DESKTOP = "Hyprland"; # Indicates Wayland session
      NIXPKGS_ALLOW_UNFREE = 1;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland.override { debug = true; };
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";
      bind = [
      "$mod, ENTER, exec, alacritty"
      "$mod, Q, killactive"
      "$mod, D, exec, wofi --show drun"
      "$mod, F, exec, firefox"
      ];
      env = [
	"LIBVA_DRIVER_NAME,nvidia"
	"LD_LIBRARY_PATH,/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
	"__GLX_VENDOR_LIBRARY_NAME,nvidia"
	# It's also often helpful to include these for broader Wayland compatibility
      #  "NIXOS_OZONE_WL,1"      # For Electron apps (VSCode, Discord, etc.)
      #  "QT_QPA_PLATFORM,wayland" # For Qt apps
      #  "GDK_BACKEND,wayland"     # For GTK apps
	"GBM_BACKEND,nvidia-drm"
	"WLR_RENDERER,vulkan"
      #  "XDG_CURRENT_DESKTOP,Hyprland" # Helps some apps recognize the DE
        "XDG_SESSION_TYPE,wayland" # Indicates Wayland session
      #  "XDG_SESSION_DESKTOP,Hyprland" # Indicates Wayland session
      #  "WLR_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0"
	#"AQ_DRM_DEVICES,/dev/dri/by-path/pci-0000:01:00.0-card"
	"AQ_DRM_DEVICES,$HOME/.config/hypr/nvidia-gpu"
	"NIXPKGS_ALLOW_UNFREE,1"
	"HYPRLAND_TRACE,1"
	"AQ_TRACE,1"
	"HYPRLAND_DEBUG,1"
      ];

      # prefer_zero_gpu = true;

      cursor = {
	no_hardware_cursors = true;
      };

      general = {
	gaps_in = 5;
      };

      decoration = {
	rounding = 10;
      };

      animations = {
	enabled = true;
      };

      exec-once = [
	"waybar"
	"mako"
	"nm-applet --indicator"
      ];
    };

  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };

  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

}
