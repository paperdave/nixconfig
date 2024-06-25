#!/bin/sh
out="$HOME/Pictures/Screenshots/$(date +"%y%m%d-%H%M%Si.png")"
flameshot gui -p "$out"
if [ -e "$out" ]; then
  xclip -selection clipboard -target image/png -i "$out"
fi

