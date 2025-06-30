#!/bin/sh

mkdir -p /run/opengl-driver/lib
mkdir -p /run/opengl-driver/lib/gbm

for lib in libGL.so* libEGL.so* libGLX.so* libnvidia-*.so* libnvidia-.so* libgbm.so* libexpat.so* libxcb-randr.so* libGLdispatch.so* lib*.so*
do
  ln -sf /usr/lib/x86_64-linux-gnu/$lib /run/opengl-driver/lib/
done

find /usr/lib /usr/lib/x86_64-linux-gnu -name 'dri_gbm.so' -exec ln -sf {} /run/opengl-driver/lib/gbm/ \;
find /usr/lib /usr/lib/x86_64-linux-gnu -name '*gbm*.so*' -exec ln -sf {} /run/opengl-driver/lib/gbm/ \;
find /usr/lib /usr/lib/x86_64-linux-gnu -name '*dri*.so*' -exec ln -sf {} /run/opengl-driver/lib/gbm/ \;
find /usr/lib /usr/lib/x86_64-linux-gnu -name 'libgm.so*' -exec ln -sf {} /run/opengl-driver/lib/gbm/ \;
#find /usr/lib /usr/lib/x86_64-linux-gnu -name '*_dri.so*' -exec ln -sf {} /run/opengl-driver/lib/gbm/ \;
# find /usr/lib /usr/lib/x86_64-linux-gnu -name 'libnvidia-egl-gbm.so*' -exec ln -sf {} /run/opengl-driver/lib/gbm/ \;



rm -f /run/opengl-driver/lib/libc.so* /run/opengl-driver/lib/libstdc++.so* /run/opengl-driver/lib/libwayland-*.so* /run/opengl-driver/lib/libweston-.so* /run/opengl-driver/lib/libnixstore.so* /run/opengl-driver/lib/libsqlite3.so* /run/opengl-driver/lib/libm.so* /run/opengl-driver/lib/libinput*.so* /run/opengl-driver/lib/libwacom.so* /run/opengl-driver/lib/libaquamarine.so* /run/opengl-driver/lib/libaquamarine.so.7* /run/opengl-driver/lib/libdrm.so*

unset LIBGL_DRIVERS_PATH
unset LD_LIBARY_PATH
unset GBM_LIBRARY_PATH


export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/gbm
export NIXPKGS_ALLOW_UNFREE=1
export LD_LIBRARY_PATH=/run/opengl-driver/lib

