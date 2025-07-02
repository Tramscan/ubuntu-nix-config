#!/bin/sh

source ~/.nix-profile/etc/profile.d/hm-session-vars.sh

#export LD_LIBRARY_PATH=/run/opengl-driver/lib
#export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm
exec /home/nick/.nix-profile/bin/Hyprland "$@"

