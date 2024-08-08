#!/bin/bash

stdbuf -oL speedtest | {
	downline=""
	upline=""
	bothline=""
	while IFS= read -r line
	do
		grabline=$( echo $line | awk  '{FS=": "} /Mbit/ { print $2" "$3 }') 
		if [[ $grabline ]]; then
			bothline+=$grabline" "
		fi
	done
	downline=$( echo $bothline | awk '{ print $1" "$2 }')
	upline=$(echo $bothline | awk '{ print $3" "$4 }')
	printedline="DOWN: "$downline" UP: "$upline
	echo $printedline
	echo $bothline
}
