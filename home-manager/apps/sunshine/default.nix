# ./apps/sunshine/default.nix
# This module installs Sunshine and sets up a systemd user service for it.

{ pkgs, ... }:

{
  # Install the Sunshine package so the binary is available.
  home.packages = with pkgs; [
    sunshine
  ];

  # Define and enable a systemd service that runs as your user.
  systemd.user.services.sunshine = {
    Unit = {
      Description = "Sunshine Game Stream Host";
      After = [ "graphical-session.target" "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      # The command to start sunshine.
      # Nix will replace ${pkgs.sunshine} with the correct path.
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      RestartSec = "3";
    };

    Install = {
      # Start the service automatically when you log in.
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
