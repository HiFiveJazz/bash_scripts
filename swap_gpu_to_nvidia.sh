#!/bin/bash

# Request sudo if not running as root
if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

# Variables
PCI_VGA="0000:03:00.0"  # 4090 PCI address
PCI_AUDIO="0000:03:00.1"
BOOT_ENTRY="/boot/loader/entries/2024-12-26_04-35-35_linux.conf"
VFIO_IDS="vfio-pci.ids=10de:2684,10de:22ba"
NVIDIA_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
GPU_INFO=$(nvidia-smi --query-gpu=index,gpu_name,display_active --format=csv,noheader)

# Check if the NVIDIA driver is already in use
check_nvidia_driver() {
    OUTPUT=$(lspci -k -d 10de:2684)
    KERNEL_DRIVER=$(echo "$OUTPUT" | grep "Kernel driver in use" | awk -F': ' '{print $2}')
    if [[ "$KERNEL_DRIVER" == *"nvidia"* ]]; then
        echo "The NVIDIA driver is already in use for the 4090. Exiting."
        exit 0
    fi
}

# Check if any GPU named 4090 is actively driving a display
while IFS=',' read -r GPU_INDEX GPU_NAME DISPLAY_STATUS; do
    GPU_INDEX=$(echo "$GPU_INDEX" | xargs)
    GPU_NAME=$(echo "$GPU_NAME" | xargs)
    DISPLAY_STATUS=$(echo "$DISPLAY_STATUS" | xargs)

    if [[ "$GPU_NAME" == *"4090"* && "$DISPLAY_STATUS" == "Enabled" ]]; then
        echo "$GPU_NAME is actively driving a display. Exiting to prevent driver removal."
        exit 0
    fi
done <<< "$GPU_INFO"

# If the 4090 is not driving a display and NVIDIA driver is not in use, proceed with passthrough setup
echo "NVIDIA GeForce RTX 4090 is not actively driving a display and NVIDIA driver is not in use. Proceeding with passthrough setup..."

check_nvidia_driver

# Unbind devices from vfio-pci
echo "Unbinding devices from vfio-pci..."
echo "$PCI_VGA" > /sys/bus/pci/devices/$PCI_VGA/driver/unbind
echo "$PCI_AUDIO" > /sys/bus/pci/devices/$PCI_AUDIO/driver/unbind

# Load NVIDIA modules
echo "Loading NVIDIA modules..."
for module in $NVIDIA_MODULES; do
    modprobe $module
done

# Bind devices to NVIDIA driver
echo "Binding devices to NVIDIA driver..."
echo "$PCI_VGA" > /sys/bus/pci/drivers/nvidia/bind
echo "$PCI_AUDIO" > /sys/bus/pci/drivers/nvidia/bind

# Remove vfio-pci settings from boot entry
echo "Updating boot entry to remove vfio-pci configuration..."
if grep -q "$VFIO_IDS" "$BOOT_ENTRY"; then
    sed -i "s/$VFIO_IDS//g" "$BOOT_ENTRY"
    echo "Removed vfio-pci.ids from boot entry."
else
    echo "vfio-pci.ids not found in boot entry."
fi

# Rebuild initramfs
echo "Rebuilding initramfs..."
mkinitcpio -P

# Prompt for reboot
echo "Switch complete. Please reboot your system to apply"

