#!/bin/bash

########################################################################################
# Disk Partitioning Module                                                             #
# Description: Interactive disk selection and partitioning for Arch Linux installation #
########################################################################################

get_available_disks() { 
    local disks=$(lsblk -dpno NAME,SIZE,MODEL | grep -E '^/dev/(sd|nvme|vd)')

    if [[ -z "$disks" ]]; then
        error "No suitable disks found"
    fi

    echo "$disks"
}

select_disk() {
    local selected_disk=$(get_available_disks | fzf --height 10 \
        --header="Select disk for installation (Use arrow keys, press Enter to select)" \
        --layout=reverse)

    if [[ -z "$selected_disk" ]]; then
        error "No disk selected"
    fi

    echo "$selected_disk" | cut -d' ' -f1
}

get_ram_size() {
    local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$(((mem_kb + 1048575) / 1048576))
    echo "$mem_gb"
}

calculate_swap_size() {
    local ram_size=$(get_ram_size)
    local swap_size

    if (( ram_size <= 2 )); then
        swap_size=$((ram_size * 2))
    elif (( ram_size <= 8 )); then
        swap_size=$ram_size
    elif (( ram_size <= 64 )); then
        swap_size=$((ram_size / 2))
    else
        swap_size=32
    fi

    echo "$swap_size"
}

confirm_disk_operation() {
    local disk="$1"
    local swap_size="$2"

    warn "WARNING: This will erase ALL data on $disk"
    info "Disk: $disk"
    info "EFI Partition: 256MB"
    info "Swap Partition: ${swap_size}GB"
    info "Root Partition: Remaining space"

    read -p "Do you want to continue? (y/N) " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        error "Operation cancelled by user"
    fi
}

create_partitions() {
    local disk="$1"
    local swap_size="$2"

    log "Creating partitions on $disk..."

    # Erase disk signatures
    wipefs -af "$disk"

    # Create GPT partition table
    parted -s "$disk" mklabel gpt

    # Create partitions
    local current_position=1

    log "Creating EFI partition..."
    parted -s "$disk" mkpart primary fat32 "${current_position}MiB" "256MiB"
    parted -s "$disk" set 1 esp on
    current_position=256

    log "Creating swap partition..."
    local swap_end=$((current_position + swap_size * 1024))
    parted -s "$disk" mkpart primary linux-swap "${current_position}MiB" "${swap_end}MiB"
    current_position=$swap_end

    log "Create root partition..."
    parted -s "$disk" mkpart primary ext4 "${current_position}MiB" 100%

    # Wait for partitions to be created
    sleep 2
}

format_partitions() {
    local disk="$1"
    local partition_prefix

    if [[ "$disk" =~ "nvme" ]]; then
        partition_prefix="${disk}p"
    else
        partition_prefix="${disk}"
    fi

    log "Formatting partitions..."

    info "Formatting EFI partition..."
    mkfs.fat -F32 "${partition_prefix}1"

    info "Formatting swap partition..."
    mkswap "${partition_prefix}2"

    info "Formatting root partition..."
    mkfs.ext4 -F "${partition_prefix}3"
}

mount_partitions() {
    local disk="$1"
    local partition_prefix

    if [[ "$disk" =~ "nvme" ]]; then
        partition_prefix="${disk}p"
    else
        partition_prefix="${disk}"
    fi

    log "Mounting partitions..."

    # Mount root partition
    mount "${partition_prefix}3" /mnt

    # Create and mount EFI directory
    mkdir -p /mnt/boot/efi
    mount "${partition_prefix}1" /mnt/boot/efi

    # Enable swap
    swapon "${partition_prefix}2"
}

install_essential_packages() {
    log "Install essential packages..."S

    pacstrap -i /mnt \
        base \
        base-devel \
        linux \
        linux-firmware \
        sudo \
        vim

    genfstab -U -p /mnt > /mnt/etc/fstab || error "Failed to generate fstab"
}
