let
  backgroundlocation = "/usr/share/wallpapers/Cluster/contents/images/3840x2160.png";
in {lib, ...}: {
  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      config = {
        modifier = "Mod4";
	fonts = {
          names = ["monospace"];
  	  size = 8.0;
	  };
        startup = [
	  { command = "dex --autostart --environment i3"; notification = false; }
	  { command = "xrandr --output DP-2 --auto --left-of DP-0 &"; notification = false; }
	  { command = "xss-lock --transfer-sleep-lock -- i3lock --nofork"; notification = false; }
	  { command = "nm-applet"; notification = false; }
	  { command = "picom -f"; always = true; notification = false; }
	  { command = "feh --bg-fill "+"${backgroundlocation}"; notification = false; }
	  ];
        
        gaps = {
	  inner = 6;
	};
	floating.border = 0;
	window.border = 0;
	window.titlebar = false;
	floating.titlebar = false;
        terminal =  "alacritty";
        #keybindings = let modifier = "Mod4"; in lib.mkDefault {
	#  "${modifier}+Return" = "exec --no-startup-id alacritty";
	#};

#        keybindings = {
#	  lib.mkOptionDefault = {
#            "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%";
#	    "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%";
#	    "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
#	    "XF86AudioMicMute" = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";
#	  };
#        };
        bars = [{
	  statusCommand = "SCRIPTS=../i3blocks/scripts i3blocks -c ~/.config/nix/home-manager/apps/i3blocks/config";
	  }];
      };
    };
  };
}
