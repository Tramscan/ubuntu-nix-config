#!/bin/bash

UPTIME=$( uptime | awk '/up/ {print $3}' | sed 's/\,//g' )
echo "Uptime: $UPTIME"
