
wayland.windowManager.hyprland = {
  enable = true;
  package = config.lib.nixGL.wrap pkgs.hyprland;
  settings = {
    env = [
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "LIBVA_DRIVER_NAME,nvidia"
    ];
  };
};
