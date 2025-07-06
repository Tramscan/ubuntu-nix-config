#!/bin/sh

source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
env > /tmp/env_tty_hyprland
#export LD_LIBRARY_PATH=/run/opengl-driver/lib
#export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm
exec Hyprland

