#!/bin/bash

GPUUTIL=$( nvidia-smi -q -d=UTILIZATION | awk '{FS=":"}; /Gpu/ {print $2}' )
echo "GPU Util: $GPUUTIL"
echo "GPUUTIL: $GPUUTIL"
[ ${GPUUTIL%?} -ge 80 ] && echo "#FF0000"
[ ${GPUUTIL%?} -ge 50 ] && echo "#FF7000"
[ ${GPUUTIL%?} -le 30 ] && echo "#00FF00"
