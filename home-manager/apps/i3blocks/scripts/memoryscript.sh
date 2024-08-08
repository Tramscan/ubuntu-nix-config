#!/bin/bash

awk '/MemFree/{ printf("%.1fG/n", $2/1024/1024) }' /proc/meminfo
