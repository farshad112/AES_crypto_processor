#!/bin/bash
###########################################################
# Script Name: ruscript.sh
# Author: Farshad
# Description: Running simulation
###########################################################
mode=$1

if [ -z "$mode" ]; then
    mode="gui"
fi

irun -f filelist.f -timescale 1ns/1ps -access +rwc -$mode 