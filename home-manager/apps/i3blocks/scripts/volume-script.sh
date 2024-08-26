#!/bin/bash

vol_bracket= amixer get Master | awk '/%/ {print $4}'
echo $vol_bracket | sed 's/[][]//g'

