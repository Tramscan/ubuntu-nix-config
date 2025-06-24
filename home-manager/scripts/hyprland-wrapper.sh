#!/bin/sh
~/.config/nix/home-manager/scripts/setup-opengl-symlinks.sh
export LD_LIBRARY_PATH=/run/opengl-driver/lib
export GBM_DRIVERS_PATH=/run/opengl-driver/lib/gbm
export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm
exec Hyprland "$@"

