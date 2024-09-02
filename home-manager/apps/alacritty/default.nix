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
    ###
    #debug = {
    #  persistent_logging = true;
    #  print_events = true;
    #  prefer_egl = true;
    #};
    ###
  };
}
