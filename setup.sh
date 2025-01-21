#!/bin/bash

# Fail on any error
set -e

source ./setup/utils.sh
check_root
enable_pacman_parallel

# Synchronize pacman packages
pacman -Syy

source ./setup/partitioning.sh
SELECTED_DISK=$(select_disk)
SWAP_SIZE=$(calculate_swap_size)
pacman -S fzf --noconfirm --needed --quiet
confirm_disk_operation "$SELECTED_DISK" "$SWAP_SIZE"
create_partitions "$SELECTED_DISK" "$SWAP_SIZE"
format_partitions "$SELECTED_DISK"
mount_partitions "$SELECTED_DISK"
log "Disk partitioning completed successfully"
install_essential_packages
