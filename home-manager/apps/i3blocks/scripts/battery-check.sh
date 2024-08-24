#!/bin/bash

percent=$( upower -d | grep "percentage" | awk 'END {print $2}' )
echo "Battery:" "$percent"
