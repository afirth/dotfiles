#!/usr/bin/env bash
set -eux -o pipefail

#toggle between single and dual monitor, even if 2nd monitor is plugged in

INTERNAL=eDP-1
EXTERNAL=DP-1-1

xrandr | grep "$EXTERNAL disconnected" > /dev/null \
    && xrandr --output $INTERNAL --auto \
  || xrandr --listactivemonitors | grep $EXTERNAL > /dev/null \
    && xrandr --output $EXTERNAL --off --output $INTERNAL --auto \
  || xrandr --output $EXTERNAL --auto --output $INTERNAL --right-of $EXTERNAL
