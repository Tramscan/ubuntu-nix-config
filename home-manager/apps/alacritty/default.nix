{

  programs.alacritty.enable = true;
  programs.alacritty.settings = {
    window = {
      dimensions = {
        lines = 15;
        columns = 60;
      };
      opacity = 0.9;
      blur = true;
      dynamic_title = true;
      decorations = "None";
    };
    env = {
      WINIT_X11_SCALE_FACTOR = "2";
    };

  };
}
