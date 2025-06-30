#!/bin/sh

/home/nick/.config/nix/home-manager/scripts/setup-opengl-symlinks.sh

#export LD_LIBRARY_PATH=/run/opengl-driver/lib
#export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm
exec /home/nick/.nix-profile/bin/Hyprland "$@"

