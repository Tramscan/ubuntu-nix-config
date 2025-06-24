#!/bin/sh
set -e

mkdir -p /run/opengl-driver/lib
mkdir -p /run/opengl-driver/lib/gbm

for lib in libGL.so* libEGL.so* libGLX.so* libnvidia-*.so* libgbm.so* libvulkan.so* libcuda.so* libOpenCL.so* libva.so* libdrm.so*; do
  find /usr/lib /usr/lib/x86_64-linux-gnu -name "$lib" -exec ln -sf {} /run/opengl-driver/lib/ \;
done

find /usr/lib /usr/lib/x86_64-linux-gnu -name '*gbm*.so*' -exec ln -sf {} /run/opengl-driver/lib/gbm/ \;
find /usr/lib /usr/lib/x86_64-linux-gnu -name '*dri*.so*' -exec ln -sf {} /run/opengl-driver/lib/gbm/ \;

rm -f /run/opengl-driver/lib/libc.so* /run/opengl-driver/lib/libstdc++.so* /run/opengl-driver/lib/libwayland-*.so* /run/opengl-driver/lib/libweston-*.so*
