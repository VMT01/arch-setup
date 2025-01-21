#!/bin/bash

# Fail on any error
set -e

# Basic setup
source ./setup/utils.sh
check_root
enable_pacman_parallel

# Synchronize pacman packages
pacman -Syy

# Disk partitioning
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

# Basic configuration
source ./setup/base_configuration.sh
read -p "Enter hostname: " hostname
read -p "Enter username: " username
install_base_packages
configure_locale
TIMEZONE=$(select_timezone)
configure_timezone "$TIMEZONE"
configure_network "$hostname"
configure_users "$username"
configure_bootloader
