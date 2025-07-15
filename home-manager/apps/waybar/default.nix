{ pkgs , ... }: {

  programs.waybar = {
    enable = true;
    style = ./style.css;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      output = [
	"DP-3"
	"DP-2"
      ];
      modules-left = [ "sway/workspaces" "sway/mode" "wlr/taskbar" ];
      modules-right = [ "mpd" "pulseaudio" "clock" "custom/spacer" "custom/shutdown" "custom/reboot" "custom/logout"];
      modules-center = [ "hyprland/workspaces" ];
      
      "hyprland/workspaces"= {
	format = "{id}";
	on-click = "activate";
	all-outputs = true;
      };


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
