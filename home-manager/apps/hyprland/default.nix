{ config, pkgs, lib, inputs, nixgl, ...}:

{
  home.sessionVariables = {
      WLR_RENDERER = "vulkan";
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
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
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";
      bind = [
      "$mod, Return, exec, alacritty"
      "$mod, Q, killactive"
      "$mod, D, exec, wofi --show drun"
      "$mod, F, exec, firefox"
      ];
      env = [
	"LIBVA_DRIVER_NAME,nvidia"
	"__GLX_VENDOR_LIBRARY_NAME,nvidia"
	# It's also often helpful to include these for broader Wayland compatibility
        "NIXOS_OZONE_WL,1"      # For Electron apps (VSCode, Discord, etc.)
        "QT_QPA_PLATFORM,wayland" # For Qt apps
        "GDK_BACKEND,wayland"     # For GTK apps
	"GBM_BACKEND,nvidia-drm"
	"WLR_RENDERER,vulkan"
        "XDG_SESSION_TYPE,wayland" # Indicates Wayland session
      #  "WLR_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0"
	#"AQ_DRM_DEVICES,/dev/dri/by-path/pci-0000:01:00.0-card"
	"AQ_DRM_DEVICES,$HOME/.config/hypr/nvidia-gpu" # future fix, need to create instructions or a script on how to set this up if needed
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
	"alacritty"
	"ghostyy"
	"firefox"
	"waybar"
	"mako"
	"nm-applet --indicator"
	"vesktop"
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
