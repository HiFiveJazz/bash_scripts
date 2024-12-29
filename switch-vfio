#!/bin/bash

# Ensure the script runs as root
# Request sudo if not running as root
if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

# Variables
PCI_VGA="0000:03:00.0"
PCI_AUDIO="0000:03:00.1"
BOOT_ENTRY="/boot/loader/entries/2024-12-26_04-35-35_linux.conf"
VFIO_IDS="vfio-pci.ids=10de:2684,10de:22ba"
VFIO_MODULES="vfio vfio-pci vfio_iommu_type1"
GPU_INFO=$(nvidia-smi --query-gpu=index,gpu_name,display_active --format=csv,noheader)

check_vfio_driver() {
    OUTPUT=$(lspci -k -d 10de:2684)
    KERNEL_DRIVER=$(echo "$OUTPUT" | grep "Kernel driver in use" | awk -F': ' '{print $2}')
    if [[ "$KERNEL_DRIVER" == *"vfio-pci"* ]]; then
        echo "The VFIO driver is already in use for the 4090. Exiting."
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

check_vfio_driver

# Unbind devices from NVIDIA driver
echo "Unbinding devices from NVIDIA driver..."
echo "$PCI_VGA" > /sys/bus/pci/devices/$PCI_VGA/driver/unbind
echo "$PCI_AUDIO" > /sys/bus/pci/devices/$PCI_AUDIO/driver/unbind

# Load vfio-pci modules
echo "Loading vfio-pci modules..."
for module in $VFIO_MODULES; do
    modprobe $module
done

# Bind devices to vfio-pci driver
echo "Binding devices to vfio-pci..."
echo "$PCI_VGA" > /sys/bus/pci/drivers/vfio-pci/bind
echo "$PCI_AUDIO" > /sys/bus/pci/drivers/vfio-pci/bind

# Update boot entry to include vfio-pci configuration
echo "Updating boot entry to include vfio-pci configuration..."
if ! grep -q "$VFIO_IDS" "$BOOT_ENTRY"; then
    sed -i "s/options /options $VFIO_IDS /" "$BOOT_ENTRY"
    echo "Added vfio-pci.ids to boot entry."
else
    echo "vfio-pci.ids already present in boot entry."
fi

# Rebuild initramfs
echo "Rebuilding initramfs..."
mkinitcpio -P

# Prompt for reboot
echo "Switch complete. Please reboot your system to apply changes."

