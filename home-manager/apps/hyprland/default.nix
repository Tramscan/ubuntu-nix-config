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

      # Workspace switching
      "SUPER, 1, workspace, 1"
      "SUPER, 2, workspace, 2"
      "SUPER, 3, workspace, 3"
      "SUPER, 4, workspace, 4"
      "SUPER, 5, workspace, 5"
      "SUPER, 6, workspace, 6"
      "SUPER, 7, workspace, 7"
      "SUPER, 8, workspace, 8"
      "SUPER, 9, workspace, 9"
      "SUPER, 0, workspace, 10"

      # Move active window to workspace
      "SUPER SHIFT, 1, movetoworkspace, 1"
      "SUPER SHIFT, 2, movetoworkspace, 2"
      "SUPER SHIFT, 3, movetoworkspace, 3"
      "SUPER SHIFT, 4, movetoworkspace, 4"
      "SUPER SHIFT, 5, movetoworkspace, 5"
      "SUPER SHIFT, 6, movetoworkspace, 6"
      "SUPER SHIFT, 7, movetoworkspace, 7"
      "SUPER SHIFT, 8, movetoworkspace, 8"
      "SUPER SHIFT, 9, movetoworkspace, 9"
      "SUPER SHIFT, 0, movetoworkspace, 10"

      # Window movement
      "SUPER, left, movefocus, l"
      "SUPER, right, movefocus, r"
      "SUPER, up, movefocus, u"
      "SUPER, down, movefocus, d"

      # Resize windows with mouse
      #"mouse:272, SUPER, resizewindow" # Left click + SUPER to resize
      #"mouse:273, SUPER, movewindow"   # Right click + SUPER to move

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
      
      decoration = {
	active_opacity = 0.875;
	inactive_opacity = 0.875;
      };

      windowrule = [
	"opacity 1.0 override, fullscreen:1"
      ];

      # prefer_zero_gpu = true;

      monitor = [
	"DP-3,2560x1440@144,0x0,1"
	"DP-2,2560x1440@144,2560x0,1"
	"HDMI-1,3840x2160@60,-3840x0,1"
	"HEADLESS-1, 3840x2160@144, auto, 1"
	"HEADLESS-2, 3840x2160@144, auto, 1"
	"HEADLESS-3, 3840x2160@144, auto, 1"
      ];

      workspace = [
	"1, monitor:DP-3, persistent:true"
	"2, monitor:DP-2, persistent:true"
	"10, monitor:HEADLESS-1, persistent:true"
	"11, monitor:HEADLESS-2, persistent:true"
	"12, monitor:HEADLESS-3, persistent:true"
      ];

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
