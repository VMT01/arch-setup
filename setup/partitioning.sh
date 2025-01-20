#!/bin/bash

pacman -Syy fzf # Display storage name

echo -e "\n\n========== Partitioning disk ==========\n\n"

# Detect storage device name
STORAGE_DEVICES=$(lsblk -dn -o NAME,SIZE | awk '{print "/dev/" $1 " - " $2}')
echo "Select a storage device using arrow keys:"
SELECTED_STORAGE_DEVICE=$(echo "$STORAGE_DEVICES" | fzf --prompt="Storage Device>" --height=10 --border)
if [ -z "$SELECTED_STORAGE_DEVICE" ]; then
    echo "No device selected!"
else
    SELECTED_STORAGE_DEVICE=$(echo "$SELECTED_STORAGE_DEVICE" | awk '{print $1}')
    echo "You selected: $SELECTED_STORAGE_DEVICE"
fi

# Setup boot partition size
BOOT_PARTITION_SIZE="256" # NOTE: MB
read -p "Boot partition size (default = $BOOT_PARTITION_SIZE MB): " input
BOOT_PARTITION_SIZE=${input:-$BOOT_PARTITION_SIZE}
echo "Boot partition size you chose: $BOOT_PARTITION_SIZE MB"

# Setup swap partition size
RAM_SIZE=$(grep MemTotal /proc/meminfo| awk '{print $2}')
RAM_SIZE=$(echo "scale=0;($RAM_SIZE+1048575)/1048576" | bc)
echo "Detected RAM size: $RAM_SIZE GB"
SWAP_PARTITION_SIZE=$((RAM_SIZE*2)) # NOTE: GB
read -p "Swap partition size (default = $SWAP_PARTITION_SIZE GB): " input
SWAP_PARTITION_SIZE=${input:-$SWAP_PARTITION_SIZE}
echo "Swap partition size you chose: $SWAP_PARTITION_SIZE GB"

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can 
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${SELECTED_STORAGE_DEVICE}
    d # delete old partition
    d # delete old partition
    d # delete old partition
    o # clear the in memory partition table
    n # new partition
    p # primary partition
    1 # partition number 1
      # default - start at beginning of disk
    +${BOOT_PARTITION_SIZE}M # boot partition size
    n # new partition
    p # primary partition
    2 # partion number 2
      # default, start immediately after preceding partition
    -${SWAP_PARTITION_SIZE}G # Double size of your ram
    n # new partition
    p # primary partition
    3 # partion number 2
      # default, start immediately after preceding partition
      # default, extend partition to end of disk
    t # change partition types
    1 # bootable partition is partition 1 -- /dev/sda1
    uefi # Boot partition UEFI
    t # change partition types
    2 # bootable partition is partition 2 -- /dev/sda2
    linux # Linux partition
    t # change partition types
    3 # bootable partition is partition 3 -- /dev/sda3
    swap # Linux partition
    w # write the partition table
    q # and we're done
EOF

mkfs.fat -F 32 "${SELECTED_STORAGE_DEVICE}1"
mkfs -t ext4 "${SELECTED_STORAGE_DEVICE}2"
mkswap "${SELECTED_STORAGE_DEVICE}3"
