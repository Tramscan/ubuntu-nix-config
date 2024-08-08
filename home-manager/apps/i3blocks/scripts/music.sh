#!/bin/bash

RUNNING_SINK=$( pactl list sinks short | grep 'RUNNING' | awk '{ print $1 }' )
RUNNING_SOURCE=$( pactl list sources short | grep 'RUNNNING' | awk '{ print $1 }' )
DEFAULT_SINK=$( pactl get-default-sink )
DEFAULT_SOURCE=$( pactl get-default-source )
SINK_VOLUME=""
SOURCE_VOLUME=""

if [ $RUNNING_SINK ] then
	SINK_VOLUME = $( pactl get-sink-volume $RUNNING_SINK )
else
	SINK_VOLUME = $( pactl get-sink-volume $DEFAULT_SINK )
fi

if [ $RUNNING_SOURCE ] then
	SOURCE_VOLUME = $( pactl get-source-volume $RUNNING_SOURCE )
else
	SOURCE_VOLUME = $( pactl get-source-volume $DEFAULT_SOURCE )
fi

echo "􀊨 : "$SOURCE_VOLUME" 􀊰 : "$SINK_VOLUME
echo "􀊨 : "$SOURCE_VOLUME" 􀊰 : "$SINK_VOLUME
