#!/bin/bash

df -h -P -l "/" | awk '/\/.*/ { print $4 }' 
