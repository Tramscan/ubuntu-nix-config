{ config, pkgs, ...}:

{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      bind = [
      "$mod, ENTER, exec, alacritty"
      "$mod, Q, killactive"
      "$mod, D, exec, wofi --show drun"
      ];

      general = {
	gaps_in = 5;
      };

      decoration = {
	rounding = 10;
      };

      animations = {
	enabled = true;
      };

      env = [
      "LIBVA_DRIVER_NAME,nvidia",
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      ];

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
