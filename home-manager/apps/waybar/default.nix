{ pkgs , ... }: 
let 

    tailscale-toggle-script = pkgs.writeShellScriptBin "waybar-tailscale" ''
    #!/usr/bin/env bash
    # This script toggles Tailscale on or off and then refreshes Waybar.

    # Check if tailscaled is active.
    if tailscale status &>/dev/null; then
        # If it's on, turn it off.
        sudo tailscale down
    else
        # If it's off, turn it on.
        sudo tailscale up
    fi

    # Signal Waybar to refresh its modules to update the icon immediately.
    # This works for Hyprland/Sway.
    pkill -RTMIN+8 waybar
  '';

in {

  home.packages = [ tailscale-toggle-script ];

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
      modules-right = [ "mpd" "custom/tailscale" "pulseaudio" "clock" "custom/spacer" "custom/shutdown" "custom/reboot" "custom/logout"];
      modules-center = [ "hyprland/workspaces" ];
      
      "hyprland/workspaces"= {
	format = "{id}";
	on-click = "activate";
	all-outputs = true;
      };

      "custom/tailscale"  = {
        # This script runs on startup and when signaled to check the status.
        exec = ''
          #!/usr/bin/env bash
          if tailscale status &>/dev/null; then
              echo '{text = "Up"; tooltip = "Tailscale is Active"; class = "on";}'
          else
              echo '{"text": "Down", "tooltip": "Tailscale is Inactive", "class": "off"}'
          fi
        '';

        format = "󰌙 {text}"; # VPN icon from Nerd Fonts
        on-click = "waybar-tailscale"; # Runs the script we defined above
        restart-interval = 3600; # Effectively run once, but restart if it crashes
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
