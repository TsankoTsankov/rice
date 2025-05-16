#!/bin/bash
# WallpaperSelect.sh - Rofi wallpaper picker: ONLY image previews, no text
# Author: (TsankoTsankov, adapted for image-only Rofi menu)
# Project: Personal dotfiles
#
# This script lets you select a wallpaper (image or video) using a rofi menu.
# After you select a wallpaper, it applies it using swww or mpvpaper,
# generates pywal colors (if an image), updates Waybar's colors.css, and reloads Waybar.
#
# Requirements: swww, mpvpaper, wal (pywal), rofi, jq, bc, magick, ffmpeg, notify-send

# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# This script for selecting wallpapers (SUPER W)

# --- CONFIGURABLE PATHS ---
terminal=kitty
wallDIR="$HOME/Pictures/WallHalla"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"
colors_file="$HOME/.config/waybar/colors.css"
last_wallpaper_file="/tmp/last_wallpaper_path"

# Get currently set wallpaper (for pywal)
#chosen=$(swww query | grep -oP '(?<=image: )(.*)' | head -n 1)

# Generate pywal colors from current wallpaper
#wal -i "$chosen" --backend haishoku
#if [ $? -ne 0 ]; then
#  notify-send "Pywal failed" "Could not generate colors with wal"
#  exit 1
#fi

# Ensure pywal colors file exists
#if [ ! -f ~/.cache/wal/colors ]; then
#  notify-send "No wal colors" "File ~/.cache/wal/colors not found"
#  exit 1
#fi

# Generate Waybar colors.css from pywal colors
#cat > "$colors_file" <<EOF
#@define-color base $(head -n 1 ~/.cache/wal/colors);
#@define-color crust $(head -n 2 ~/.cache/wal/colors | tail -n 1);
#@define-color text $(head -n 16 ~/.cache/wal/colors | tail -n 1);
#@define-color red $(head -n 2 ~/.cache/wal/colors | tail -n 1);
#@define-color green $(head -n 3 ~/.cache/wal/colors | tail -n 1);
#@define-color yellow $(head -n 4 ~/.cache/wal/colors | tail -n 1);
#@define-color blue $(head -n 5 ~/.cache/wal/colors | tail -n 1);
#@define-color magenta $(head -n 6 ~/.cache/wal/colors | tail -n 1);
#@define-color cyan $(head -n 7 ~/.cache/wal/colors | tail -n 1);
#@define-color surface0 $(head -n 8 ~/.cache/wal/colors | tail -n 1);
#@define-color overlay0 $(head -n 9 ~/.cache/wal/colors | tail -n 1);
#@define-color peach $(head -n 10 ~/.cache/wal/colors | tail -n 1);
#@define-color teal $(head -n 11 ~/.cache/wal/colors | tail -n 1);
#@define-color sky $(head -n 12 ~/.cache/wal/colors | tail -n 1);
#@define-color sapphire $(head -n 13 ~/.cache/wal/colors | tail -n 1);
#@define-color lavender $(head -n 14 ~/.cache/wal/colors | tail -n 1);
#EOF

# Reload Waybar to apply new colors
pkill -SIGUSR2 waybar

# Check for required dependencies
if ! command -v bc &>/dev/null; then
  notify-send -i "$iDIR/error.png" "bc missing" "Install package bc first"
  exit 1
fi

# Get focused monitor info
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

# swww transition config
FPS=60
TYPE="any"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# --- Helper: Kill wallpaper daemons ---
kill_wallpaper_for_video() {
  swww kill 2>/dev/null
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}
kill_wallpaper_for_image() {
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# --- Menu Construction (JaKooLit style, minimal changes) ---
menu() {
  # Find all images and videos
  mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \(
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
    -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
    -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0)
  RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
  RANDOM_PIC_NAME=". random"

  # Print random option
  printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"

  # Sort and print all wallpapers with previews
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))
  for pic_path in "${sorted_options[@]}"; do
    pic_name=$(basename "$pic_path")
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif_image="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif_image" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        magick "$pic_path[0]" -resize 1920x1080 "$cache_gif_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_gif_image"
    elif [[ "$pic_name" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      cache_preview_image="$HOME/.cache/video_preview/${pic_name}.png"
      if [[ ! -f "$cache_preview_image" ]]; then
        mkdir -p "$HOME/.cache/video_preview"
        ffmpeg -v error -y -i "$pic_path" -ss 00:00:01.000 -vframes 1 "$cache_preview_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_preview_image"
    else
      printf "%s\x00icon\x1f%s\n" "$(echo "$pic_name" | cut -d. -f1)" "$pic_path"
    fi
  done
}

# --- Startup config update ---
modify_startup_config() {
  local selected_file="$1"
  local startup_config="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm)$ ]]; then
    sed -i '/^\s*exec-once\s*=\s*swww-daemon\s*--format\s*xrgb\s*$/s/^/\#/' "$startup_config"
    sed -i '/^\s*#\s*exec-once\s*=\s*mpvpaper\s*.*/s/^#\s*//;' "$startup_config"
    selected_file="${selected_file/#$HOME/\$HOME}"
    sed -i "s|^\$livewallpaper=.*|\$livewallpaper=\"$selected_file\"|" "$startup_config"
    echo "Configured for live wallpaper (video)."
  else
    sed -i '/^\s*#\s*exec-once\s*=\s*swww-daemon\s*--format\s*xrgb\s*$/s/^\s*#\s*//;' "$startup_config"
    sed -i '/^\s*exec-once\s*=\s*mpvpaper\s*.*/s/^/\#/' "$startup_config"
    echo "Configured for static wallpaper (image)."
  fi
}

# --- Apply wallpaper ---
apply_image_wallpaper() {
  local image_path="$1"
  kill_wallpaper_for_image
  if ! pgrep -x "swww-daemon" >/dev/null; then
    swww-daemon --format xrgb &
    sleep 0.3
  fi
  swww img -o "$focused_monitor" "$image_path" $SWWW_PARAMS
  "$SCRIPTSDIR/WallustSwww.sh"
  sleep 1
  "$SCRIPTSDIR/Refresh.sh"
  sleep 0.5
}

apply_video_wallpaper() {
  local video_path="$1"
  if ! command -v mpvpaper &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "mpvpaper not found"
    return 1
  fi
  kill_wallpaper_for_video
  mpvpaper '*' -o "load-scripts=no no-audio --loop" "$video_path" &
}

# --- Generate pywal colors and update Waybar (optimized) ---
generate_pywal_and_update_waybar() {
  local image_path="$1"
  # Only run pywal if wallpaper changed
  if [[ -f "$last_wallpaper_file" && "$(cat "$last_wallpaper_file")" == "$image_path" ]]; then
    echo "[DEBUG] Wallpaper unchanged, skipping pywal." | tee -a /tmp/wallpaper_debug.log
    return 0
  fi
  echo "$image_path" > "$last_wallpaper_file"
  echo "[DEBUG] Running: wal -i '$image_path'" | tee -a /tmp/wallpaper_debug.log
  wal -i "$image_path"
  if [ $? -ne 0 ]; then
    notify-send "Pywal failed" "Could not generate colors with wal"
    echo "[ERROR] Pywal failed for: $image_path" | tee -a /tmp/wallpaper_debug.log
    return 1
  fi
  if [ ! -f ~/.cache/wal/colors ]; then
    notify-send "No wal colors" "File ~/.cache/wal/colors not found"
    echo "[ERROR] ~/.cache/wal/colors not found after wal" | tee -a /tmp/wallpaper_debug.log
    return 1
  fi
  cat > "$colors_file" <<EOF
@define-color base $(head -n 1 ~/.cache/wal/colors);
@define-color crust $(head -n 2 ~/.cache/wal/colors | tail -n 1);
@define-color text $(head -n 16 ~/.cache/wal/colors | tail -n 1);
@define-color red $(head -n 2 ~/.cache/wal/colors | tail -n 1);
@define-color green $(head -n 3 ~/.cache/wal/colors | tail -n 1);
@define-color yellow $(head -n 4 ~/.cache/wal/colors | tail -n 1);
@define-color blue $(head -n 5 ~/.cache/wal/colors | tail -n 1);
@define-color magenta $(head -n 6 ~/.cache/wal/colors | tail -n 1);
@define-color cyan $(head -n 7 ~/.cache/wal/colors | tail -n 1);
@define-color surface0 $(head -n 8 ~/.cache/wal/colors | tail -n 1);
@define-color overlay0 $(head -n 9 ~/.cache/wal/colors | tail -n 1);
@define-color peach $(head -n 10 ~/.cache/wal/colors | tail -n 1);
@define-color teal $(head -n 11 ~/.cache/wal/colors | tail -n 1);
@define-color sky $(head -n 12 ~/.cache/wal/colors | tail -n 1);
@define-color sapphire $(head -n 13 ~/.cache/wal/colors | tail -n 1);
@define-color lavender $(head -n 14 ~/.cache/wal/colors | tail -n 1);
EOF
  pkill -SIGUSR2 waybar &
  echo "[DEBUG] Updated $colors_file and reloaded waybar" | tee -a /tmp/wallpaper_debug.log
}

# --- Main logic ---
main() {
  # Prevent multiple rofi instances
  if pidof rofi >/dev/null; then
    pkill rofi
    sleep 0.2
  fi

  choice=$(menu | rofi -dmenu -show-icons -theme "$rofi_theme" -theme-str "$rofi_override")
  choice=$(echo "$choice" | xargs)
  RANDOM_PIC_NAME=". random"

  if [[ -z "$choice" ]]; then
    echo "No choice selected. Exiting."
    exit 0
  fi

  # Handle random selection
  if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
    choice=$(basename "$RANDOM_PIC")
  fi

  choice_basename=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')

  # Find the selected file in the wallpapers directory
  selected_file=$(find "$wallDIR" -iname "$choice_basename.*" -print -quit)

  if [[ -z "$selected_file" ]]; then
    echo "File not found. Selected choice: $choice"
    exit 1
  fi

  modify_startup_config "$selected_file"

  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    apply_video_wallpaper "$selected_file"
  else
    apply_image_wallpaper "$selected_file"
  fi
}

main
