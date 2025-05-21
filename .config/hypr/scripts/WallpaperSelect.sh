#!/bin/bash
# /* ---- Combined Wallpaper Selector Script with Caching and Debugging ---- */
# This script provides a Rofi menu for selecting wallpapers (images and videos)
# and optimizes the selection speed by caching the list of available wallpapers.

# --- User Configuration ---
wallDIR="$HOME/Pictures/WallHalla" # Wallpaper directory (supports subfolders)
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi" # Rofi theme configuration
startup_config_file="$HOME/.config/hypr/autostart.conf" # Hyprland startup config
CACHE_FILE="$HOME/.cache/wallpaper_list.cache" # Cache file for wallpaper paths

# --- Script Parameters ---
FPS=60
TYPE="any"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

cacheDIR_gif="$HOME/.cache/rofi_gif_preview"
cacheDIR_video="$HOME/.cache/rofi_video_preview"
mkdir -p "$cacheDIR_gif" "$cacheDIR_video" 2>/dev/null # Ensure cache directories exist

icon_error="dialog-error"
icon_info="dialog-information"
icon_success="dialog-ok"
icon_video="video-x-generic" # Generic video icon for notifications

# --- Dependency Checks ---
# (Assuming these are installed: bc, jq, rofi, swww, mpvpaper, ffmpeg, imagemagick)
for cmd in bc jq rofi swww ffmpeg magick; do
  if ! command -v "$cmd" &>/dev/null; then
    notify-send -u critical -i "$icon_error" "$cmd missing" "Install package $cmd first"
    [[ "$cmd" == "rofi" || "$cmd" == "jq" || "$cmd" == "bc" || "$cmd" == "swww" ]] && exit 1
  fi
done
if ! command -v mpvpaper &>/dev/null; then
  notify-send -u low -i "$icon_info" "mpvpaper missing" "Video wallpapers will not be available."
fi

# --- Monitor and Rofi Sizing ---
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

if [[ -z "$focused_monitor" ]]; then
  notify-send -u critical -i "$icon_error" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

# Robustly get monitor details with defaults from jq
scale_factor_raw=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale // "1.0"')
monitor_height_raw=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height // "1080"')

# Assign defaults if jq returns empty or invalid
scale_factor=${scale_factor_raw:-1.0}
monitor_height=${monitor_height_raw:-1080}

# Ensure scale_factor is not zero and is a valid number for bc
if ! [[ "$scale_factor" =~ ^[0-9]+(\.[0-9]+)?$ && $(echo "$scale_factor > 0" | bc -l) -eq 1 ]]; then
    echo "Warning: Invalid scale_factor '$scale_factor', using 1.0" >&2
    scale_factor=1.0
fi
if ! [[ "$monitor_height" =~ ^[0-9]+$ && "$monitor_height" -gt 0 ]]; then
    echo "Warning: Invalid monitor_height '$monitor_height', using 1080" >&2
    monitor_height=1080
fi

# Calculate Rofi icon size based on monitor resolution and scale
icon_size_bc=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size_num=$(echo "$icon_size_bc" | awk '{num = int($1); if (num == 0) num = 20; if (num < 15) num = 20; if (num > 40) num = 40; print num}') # Clamped between 15-40

if [[ -z "$adjusted_icon_size_num" || "$adjusted_icon_size_num" -le 0 ]]; then
    echo "Warning: adjusted_icon_size_num calculation failed ('$icon_size_bc'), using default 25%" >&2
    adjusted_icon_size_num=25
fi
echo "Rofi Icon Size Override: ${adjusted_icon_size_num}% (from scale: $scale_factor, height: $monitor_height)" >&2

# Rofi theme override for icon sizing
rofi_override="element-icon{size:${adjusted_icon_size_num}%;}"

# --- Wallpaper Caching ---
# Function to build or rebuild the cache of all supported wallpaper files
# This function now also handles thumbnail generation for speed optimization.
build_full_cache() {
    echo "Building wallpaper cache in $CACHE_FILE..." >&2
    # Find all supported wallpaper files and write their paths to a temporary file
    find -L "${wallDIR}" -type f \( \
        -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
        -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
        -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) > "$CACHE_FILE.tmp"

    # Generate thumbnails for all files found in the temporary cache file
    local count=0
    while IFS= read -r pic_path; do
        if [[ -z "$pic_path" ]]; then
            continue
        fi

        # Generate thumbnails for GIFs if magick is available and thumbnail doesn't exist
        if [[ "$pic_path" =~ \.gif$ ]] && command -v magick &>/dev/null; then
            local cache_gif_image="$cacheDIR_gif/$(basename "${pic_path}").png"
            if [[ ! -f "$cache_gif_image" ]]; then
                echo "CACHE MISS (GIF): Generating preview for $pic_path" >&2
                magick "$pic_path[0]" -thumbnail 256x256 "$cache_gif_image" 2>/dev/null
            fi
        # Generate thumbnails for videos if ffmpeg is available and thumbnail doesn't exist
        elif [[ "$pic_path" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]] && command -v ffmpeg &>/dev/null; then
            local cache_preview_image="$cacheDIR_video/$(basename "${pic_path}").png"
            if [[ ! -f "$cache_preview_image" ]]; then
                echo "CACHE MISS (Video): Generating preview for $pic_path" >&2
                ffmpeg -v error -y -i "$pic_path" -ss 00:00:01.000 -vframes 1 -vf "scale=256:-1,format=rgba" "$cache_preview_image" 2>/dev/null
            fi
        fi
        count=$((count + 1))
    done < "$CACHE_FILE.tmp"

    # Atomically replace the old cache file with the new one
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    echo "Cache built with $count entries, including thumbnails." >&2
}

# Initial cache setup or refresh if cache file is missing or outdated
# This ensures that the cache is always up-to-date and thumbnails are pre-generated.
if [[ ! -f "$CACHE_FILE" ]]; then
    build_full_cache
elif [[ "$(find "$wallDIR" -type f -newer "$CACHE_FILE" 2>/dev/null | wc -l)" -gt 0 ]]; then
    # Rebuild cache if any files in wallDIR are newer than the cache file
    build_full_cache
fi

# --- Wallpaper Handling Functions ---
kill_wallpaper_for_video() {
  pkill swww-daemon 2>/dev/null
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

# --- Rofi Menu Generation ---
menu() {
  echo "Reading pictures from cache into PICS array..." >&2
  # Read paths from cache file into PICS array
  mapfile -t PICS < "$CACHE_FILE" # -t removes trailing newlines

  if [ ${#PICS[@]} -eq 0 ]; then
      notify-send -u critical -i "$icon_error" "No Wallpapers Found" "Directory: $wallDIR (or cache is empty)"
      exit 1
  fi
  echo "Found ${#PICS[@]} pictures from cache." >&2

  # Prepare random wallpaper entry
  RANDOM_PIC_PATH="${PICS[$((RANDOM % ${#PICS[@]}))]}"
  RANDOM_PIC_NAME_DISPLAY=". Random Wallpaper"

  # Sort wallpapers by basename for Rofi display
  # Create an array of basenames, sort it, then iterate through it to find full paths.
  # This part is crucial for making the Rofi menu appear sorted.
  IFS=$'\n' sorted_basenames=($(for f in "${PICS[@]}"; do basename "$f"; done | sort))

  # Add random option first to Rofi output
  # Format: primary_value\x00icon\x1ficon_path\x00display\x1fdisplay_name\n
  # Rofi will return primary_value, display display_name, and show icon_path as icon.
  printf "%s\x00icon\x1f%s\x00display\x1f%s\n" "RANDOM_WALLPAPER_SELECTION_TOKEN" "$RANDOM_PIC_PATH" "$RANDOM_PIC_NAME_DISPLAY"

  processed_count=0
  for pic_basename_sorted in "${sorted_basenames[@]}"; do
    local pic_full_path=""
    # Find the full path for the basename from the PICS array
    # This loop is necessary because `sorted_basenames` only contains basenames.
    for p_lookup in "${PICS[@]}"; do
        if [[ "$(basename "$p_lookup")" == "$pic_basename_sorted" ]]; then
            pic_full_path="$p_lookup"
            break
        fi
    done

    if [[ -z "$pic_full_path" ]]; then
        echo "Warning: Could not find full path for basename '$pic_basename_sorted' in PICS array." >&2
        continue
    fi

    local pic_display_name="$pic_basename_sorted" # Use full filename for display
    local icon_to_use="$pic_full_path" # Default to using the image itself as icon

    # Determine the correct pre-generated thumbnail path
    if [[ "$pic_full_path" =~ \.gif$ ]]; then
      icon_to_use="$cacheDIR_gif/$(basename "${pic_full_path}").png"
    elif [[ "$pic_full_path" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      icon_to_use="$cacheDIR_video/$(basename "${pic_full_path}").png"
    fi

    # Format: primary_value\x00icon\x1ficon_path\x00display\x1fdisplay_name\n
    printf "%s\x00icon\x1f%s\x00display\x1f%s\n" "$pic_full_path" "$icon_to_use" "$pic_display_name"
    processed_count=$((processed_count + 1))
  done
  echo "Processed $processed_count items for Rofi menu." >&2
}

# --- Startup Configuration Modification ---
modify_startup_config() {
  local selected_file_path="$1"
  local config_file="$startup_config_file"

  if [[ ! -f "$config_file" ]]; then
    notify-send -u normal -i "$icon_error" "Startup Config Not Found" "Cannot persist wallpaper type. File not found: $config_file"
    return
  fi
  if [[ ! -w "$config_file" ]]; then
    notify-send -u normal -i "$icon_error" "Startup Config Not Writable" "Cannot persist wallpaper type. File not writable: $config_file"
    return
  fi

  # Use $HOME in the config file for portability
  local home_rel_path="${selected_file_path/#$HOME/\$HOME}"
  # Escape for sed: \, /, &, $
  local sed_escaped_path=$(echo "$home_rel_path" | sed -e 's/[\/&]/\\&/g' -e 's/\$/\\$/g')

  if [[ "$selected_file_path" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    echo "Configuring startup for VIDEO wallpaper: $sed_escaped_path" >&2
    # Comment out swww lines
    sed -i -E "s/^(exec-once\s*=\s*swww init.*|exec-once\s*=\s*swww-daemon.*)/# \1/" "$config_file"
    # Ensure mpvpaper line exists and is active, then update path
    if ! grep -q -E "^\s*exec-once\s*=\s*mpvpaper" "$config_file"; then
      echo -e "\n# exec-once = swww init # Ensure this or swww-daemon is present if you switch back" >> "$config_file" # Add swww if missing
      echo -e "exec-once = mpvpaper '*' -o \"no-audio --loop\" \"$sed_escaped_path\"" >> "$config_file"
    else
      sed -i -E "s/^#\s*(exec-once\s*=\s*mpvpaper.*)/\1/" "$config_file" # Uncomment if commented
      # Use | as delimiter for sed to avoid issues with slashes in path
      sed -i -E "s|^(exec-once\s*=\s*mpvpaper\s+['\"]?\S+['\"]?\s+-o\s+\")[^\"]+(\")|\1$sed_escaped_path\2|" "$config_file"
    fi
    notify-send -i "$icon_video" "Startup Configured" "Video wallpaper for next login."
  else
    echo "Configuring startup for IMAGE wallpaper: $sed_escaped_path" >&2
    # Comment out mpvpaper line
    sed -i -E "s/^(exec-once\s*=\s*mpvpaper.*)/# \1/" "$config_file"
    # Ensure swww line exists and is active
    if ! grep -q -E "^\s*exec-once\s*=\s*(swww init|swww-daemon)" "$config_file"; then
      echo -e "\n# exec-once = mpvpaper '*' -o \"no-audio --loop\" \"\$HOME/Pictures/WallHalla/default_video.mp4\"" >> "$config_file" # Add mpvpaper if missing
      echo -e "exec-once = swww init" >> "$config_file" # or swww-daemon --format xrgb
    else
      sed -i -E "s/^#\s*(exec-once\s*=\s*swww init.*|exec-once\s*=\s*swww-daemon.*)/\1/" "$config_file" # Uncomment if commented
    fi
    # For swww, it usually restores the last session. If you want to explicitly set it at startup:
    # You could add/modify: exec-once = swww img "$sed_escaped_path"
    # This script assumes swww init is enough to restore the last swww session.
    notify-send -i "$selected_file_path" "Startup Configured" "Image wallpaper for next login."
  fi
}

# --- Apply Wallpaper Functions ---
apply_image_wallpaper() {
  local image_path="$1"
  kill_wallpaper_for_image
  if ! pgrep -x "swww-daemon" > /dev/null; then
    notify-send -u low -i "$icon_info" "Starting swww-daemon..."
    swww query || swww-daemon --format xrgb & # Start daemon if not running or swww not initialized
    sleep 0.5
  fi
  swww img -o "$focused_monitor" "$image_path" $SWWW_PARAMS
  notify-send -i "$image_path" "Wallpaper Set" "$(basename "$image_path")"
}

apply_video_wallpaper() {
  local video_path="$1"
  if ! command -v mpvpaper &>/dev/null; then
    notify-send -u critical -i "$icon_error" "E-R-R-O-R" "mpvpaper not found."
    return 1
  fi
  kill_wallpaper_for_video
  sleep 0.1
  mpvpaper '*' -o "load-scripts=no no-audio --loop --no-osc --no-osd-bar --no-input-default-bindings" "$video_path" &
  notify-send -i "$icon_video" "Video Wallpaper Set" "$(basename "$video_path")"
}

# --- Main Function ---
main() {
  # Rofi selection: -show-icons is crucial for displaying thumbnails.
  # Rofi will return the primary string (the full path or the special token).
  rofi_command="rofi -i -show -dmenu -p \"Select Wallpaper\" -config $rofi_theme -theme-str $rofi_override -show-icons"
  selected_value_from_rofi=$(menu | $rofi_command) # This will be the full path or the random token

  if [[ -z "$selected_value_from_rofi" ]]; then
    echo "No choice selected. Exiting." >&2
    exit 0
  fi

  local selected_file_path=""

  # Check if the special token for random wallpaper was returned
  if [[ "$selected_value_from_rofi" == "RANDOM_WALLPAPER_SELECTION_TOKEN" ]]; then
    # If "Random Wallpaper" is chosen, pick a new random one from the PICS array.
    # The PICS array is populated by the 'menu' function, which is part of the pipeline.
    selected_file_path="${PICS[$((RANDOM % ${#PICS[@]}))]}"
    echo "Random choice selected, applying: $selected_file_path" >&2
  else
    # For regular selections, selected_value_from_rofi already contains the full path
    selected_file_path="$selected_value_from_rofi"
    echo "Regular choice selected, applying: $selected_file_path" >&2
  fi

  if [[ -z "$selected_file_path" ]] || [[ ! -f "$selected_file_path" ]]; then
    notify-send -u critical -i "$icon_error" "File Not Found" "Selected file not found or invalid: $selected_file_path (Value from Rofi: $selected_value_from_rofi)"
    exit 1
  fi
  echo "Applying wallpaper: $selected_file_path" >&2

  modify_startup_config "$selected_file_path"

  if [[ "$selected_file_path" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    apply_video_wallpaper "$selected_file_path"
  else
    apply_image_wallpaper "$selected_file_path"
  fi
}

# --- Script Execution ---
# Kill any running Rofi instance before starting a new one
if pidof rofi > /dev/null; then
  pkill rofi
  sleep 0.1
fi

main # Execute the main function

