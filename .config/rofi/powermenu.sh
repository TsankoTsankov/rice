#!/bin/bash

# --- Configuration ---
# Path to your Rofi theme file
ROFI_THEME_PATH="$HOME/.config/rofi/powermenu.rasi"

# --- System Information ---
uptime_info="`uptime -p | sed -e 's/up //g'`"
hostname_info=`hostname`

# --- Menu Options (Labels & Nerd Font Icons) ---
# Ensure FiraCode Nerd Font is installed and these glyphs are supported.
# You can find more icons at: https://www.nerdfonts.com/cheat-sheet
LABEL_SHUTDOWN='Shutdown'
ICON_SHUTDOWN='' # Font Awesome: power-off (U+F011)

LABEL_REBOOT='Reboot'
ICON_REBOOT=''   # Font Awesome: redo (U+F2F9)

LABEL_LOCK='Lock'
ICON_LOCK=''     # Font Awesome: lock (U+F023)

LABEL_SUSPEND='Suspend'
ICON_SUSPEND=''  # Font Awesome: moon (U+F186)

LABEL_LOGOUT='Logout'
ICON_LOGOUT=''   # Font Awesome: sign-out-alt (U+F2F5)

# Confirmation Options
LABEL_YES='Yes'
ICON_YES=''      # Font Awesome: check-square (U+F14A)

LABEL_NO='No'
ICON_NO=''       # Font Awesome: times (U+F00D)

# --- Rofi Command Functions ---

# Main Rofi menu for power options
rofi_main_menu() {
    rofi -dmenu \
        -p "$hostname_info" \
        -mesg "Uptime: $uptime_info" \
        -theme "$ROFI_THEME_PATH" \
        -markup-rows # Essential for icon/label separation
}

# Rofi confirmation dialog
rofi_confirm_dialog() {
    rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 250px;}' \
        -theme-str 'mainbox {children: [ "message", "listview" ];}' \
        -theme-str 'listview {columns: 2; lines: 1;}' \
        -theme-str 'element-text {horizontal-align: 0.5;}' \
        -theme-str 'textbox {horizontal-align: 0.5;}' \
        -dmenu \
        -p 'Confirmation' \
        -mesg 'Are you Sure?' \
        -theme "$ROFI_THEME_PATH" \
        -markup-rows # Essential for icon/label separation
}

# --- Core Logic ---

# Function to display confirmation and execute command
execute_command_with_confirmation() {
    local command_to_run="$1"

    # Display confirmation dialog
    local selected_confirmation
    selected_confirmation=$(echo -e "${LABEL_YES}\x00icon\x1f${ICON_YES}\n${LABEL_NO}\x00icon\x1f${ICON_NO}" | rofi_confirm_dialog)

    # Handle ESC key press or "No" selection
    if [[ -z "$selected_confirmation" || "$(echo "$selected_confirmation" | awk -F'\x00icon\x1f' '{print $1}')" == "$LABEL_NO" ]]; then
        exit 0 # Exit script without action
    fi

    # Execute the command if "Yes" was selected
    if [[ "$(echo "$selected_confirmation" | awk -F'\x00icon\x1f' '{print $1}')" == "$LABEL_YES" ]]; then
        case "$command_to_run" in
            '--shutdown')
                systemctl poweroff
                ;;
            '--reboot')
                systemctl reboot
                ;;
            '--suspend')
                mpc -q pause # Pause music player (if mpc is installed)
                amixer set Master mute # Mute audio
                systemctl suspend
                ;;
            '--logout')
                # Replace with your specific logout command (e.g., pkill X, loginctl kill-session, or desktop environment specific)
                # systemctl logout might not work for all setups, adjust as needed.
                systemctl logout
                ;;
        esac
    fi
}

# --- Main Script Execution ---

# Generate menu options for Rofi using the "label\x00icon\x1ficon_glyph" format
menu_options=$(cat <<EOF
${LABEL_LOCK}\x00icon\x1f${ICON_LOCK}
${LABEL_SUSPEND}\x00icon\x1f${ICON_SUSPEND}
${LABEL_LOGOUT}\x00icon\x1f${ICON_LOGOUT}
${LABEL_REBOOT}\x00icon\x1f${ICON_REBOOT}
${LABEL_SHUTDOWN}\x00icon\x1f${ICON_SHUTDOWN}
EOF
)

# Display the main Rofi menu
chosen_option=$(echo -e "$menu_options" | rofi_main_menu)

# Handle ESC key press on main menu
if [[ -z "$chosen_option" ]]; then
    exit 0
fi

# Extract the label from the chosen option for comparison
chosen_label=$(echo "$chosen_option" | awk -F'\x00icon\x1f' '{print $1}')

# Execute action based on chosen option
case "$chosen_label" in
    "$LABEL_SHUTDOWN")
        execute_command_with_confirmation '--shutdown'
        ;;
    "$LABEL_REBOOT")
        execute_command_with_confirmation '--reboot'
        ;;
    "$LABEL_LOCK")
        # Direct execution for lock, no confirmation needed by default
        "$HOME/.config/hypr/scripst/LockScreen.sh" # Ensure this path is correct and script is executable
        ;;
    "$LABEL_SUSPEND")
        execute_command_with_confirmation '--suspend'
        ;;
    "$LABEL_LOGOUT")
        execute_command_with_confirmation '--logout'
        ;;
esac

