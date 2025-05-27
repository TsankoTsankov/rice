#!/bin/bash

# --- Configuration Variables ---
VM_NAME="win11"
LG_CLIENT_COMMAND="looking-glass-client -m KEY_RIGHTCTRL"
NOTIFICATION_TITLE="VM Launcher"
NOTIFICATION_ICON="video-display"
FIXED_WAIT_SECONDS=20 

# --- Function for sending notifications (using notify-send for swaync) ---
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"  
    notify-send -a "$NOTIFICATION_TITLE" -i "$NOTIFICATION_ICON" -u "$urgency" "$title" "$message"
}


if virsh -c qemu:///system list --name | grep -q "^$VM_NAME$"; then
    send_notification "VM Already Running" "VM '$VM_NAME' is already active. Switching to its workspace."
    hyprctl dispatch workspace 7:WinVM

    # Check if Looking Glass client is already running. If not, launch it.
    if ! pgrep -x "looking-glass-client" > /dev/null; then
        send_notification "VM Already Running" "Launching Looking Glass client for active VM."
        exec $LG_CLIENT_COMMAND
    fi
    exit 0 
fi

send_notification "Preparing GPU" "Setting GPU to VFIO passthrough mode..."


# This should be handeled by libvert hooks, but just incase
supergfxctl -m Integrated
supergfxctl -m Vfio

if [ $? -ne 0 ]; then
    send_notification "ERROR" "Failed to set GPU to VFIO mode. Please check supergfxctl status and sudo permissions." "critical"
    exit 1 # Exit with an error code
fi

send_notification "Starting VM" "Launching VM '$VM_NAME'..."

virsh -c qemu:///system start "$VM_NAME"

# Check if the VM started successfully
if [ $? -ne 0 ]; then
    send_notification "ERROR" "Failed to start VM '$VM_NAME'. Check virsh status and VM configuration." "critical"
    exit 1
fi

send_notification "VM Booting" "Waiting $FIXED_WAIT_SECONDS seconds for VM to boot and Looking Glass host to start..."
sleep $FIXED_WAIT_SECONDS

send_notification "VM Ready!" "VM '$VM_NAME' is fully booted and ready. Launching Looking Glass client now." "normal"

exec $LG_CLIENT_COMMAND
