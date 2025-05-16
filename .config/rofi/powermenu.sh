#!/bin/bash
# Rofi Power Menu with Unicode icons as text, matching only the four options

options="  Lock\n  Logout\n  Reboot\n  Shutdown"
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" -theme ~/.config/rofi/powermenu.rasi)

case "$chosen" in
  *Lock*)     hyprlock ;;
  *Logout*)   hyprctl dispatch exit ;;
  *Reboot*)   systemctl reboot ;;
  *Shutdown*) systemctl poweroff ;;
esac 