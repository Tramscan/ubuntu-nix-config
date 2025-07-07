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
      modules-right = [ "mpd" "custom/mymodule#with-css-id" "pulseaudio" "clock" "custom/spacer" "custom/shutdown" "custom/reboot" "custom/logout"];

      "clock" = {
	format-alt = "{%H:%M}";
	tooltip = false;
      };

      "custom/shutdown" = {
	format = "  ⏻  ";
	interval = "once";
	on-click = "shutdown now";
	tooltip-format = "Shutdown Now";
      };

      "custom/reboot" = {
	format = "  ⭯  ";
	interval = "once";
	on-click = "reboot now";
	tooltip-format = "Reboot Now";
      };

      "custom/logout" = {
	format = "  ⮌  ";
	interval = "once";
	on-click = "hyprctl dispatch exit";
	tooltip-format = "Log Out";
      };

      "pulseaudio" = {
	on-click = "pavucontrol";
	format-muted = "!";
      };

      "custom/spacer" = {
	format = "	";
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
