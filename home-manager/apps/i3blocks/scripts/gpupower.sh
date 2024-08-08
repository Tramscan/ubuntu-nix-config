#!/bin/bash

GPUPOWER=$( nvidia-smi -q -d=POWER | awk '{FS=":"}; /Power Draw/  {print $2}' )
echo "GPU Draw: $GPUPOWER"
