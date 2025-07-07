{ pkgs , ... }: {

  programs.waybar = {
    enable = true;
    style = ./style.css;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      output = [
	"DP-2"
	"DP-1"
      ];
      modules-left = [ "sway/workspaces" "sway/mode" "wlr/taskbar" ];
      modules-right = [ "mpd" "custom/mymodule#with-css-id" "pulseaudio" "clock"];

      "clock" = {
	format-alt = "{:%a, %d. %b  %H:%M}";
      };

      "pulseaudio" = {
	on-click = "pavucontrol";
	format-muted = "!";
      };

      "sway/workspaces" = {
	disable-scroll = true;
	all-outputs = true;
      };
      "custom/hello-from-waybar" = {
	format = "hello {}";
	max-length = 40;
	interval = "once";
	exec = pkgs.writeShellScript "hello-from-waybar" ''
	  echo "from within waybar"
	'';
      };
    };
  };
}
