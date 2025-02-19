#!/bin/bash

enable_pacman_parallel_download() {
    clear

    log "Enabling pacman parallel downloads..."
    sed -i 's/^#\(ParallelDownloads = 5\)/\1/' /etc/pacman.conf

    sleep 2
}

install_necessary_packages() {
    clear 

    log "Install neccessary packages..."

    local packages=(
        "fzf"
        "archlinux-keyring"
    )

    pacman -S "${packages[@]}" --noconfirm --needed || error "Failed to install neccessary packages"

    sleep 2
}

select_disk() {
    local selected_disk=$(lsblk -dpno NAME,SIZE,MODEL | \
        grep -E '^/dev/(sd|nvme|vd)' | \
        fzf --header="Select disk for installation" --layout=reverse)
    if [[ -z "$selected_disk" ]]; then
        error "No disk selected"
    fi

    echo "$selected_disk" | cut -d' ' -f1
}

select_swap_size() {
    local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$(((mem_kb + 1048575) / 1048576))

    local swap_size
    if (( mem_gb <= 2 )); then
        swap_size=$((mem_gb * 2))
    elif (( mem_gb <= 8 )); then
        swap_size=$mem_gb
    elif (( mem_gb <= 64 )); then
        swap_size=$((mem_gb / 2))
    else
        swap_size=32
    fi

    echo "$swap_size"
}

confirm_disk_operation() {
    clear

    local disk="$1"
    local swap_size="$2"

    warn "This will erase ALL data on $disk"
    info "Disk: $disk"
    info "EFI Partition: 512MB"
    info "Swap Partition: ${swap_size}GB"
    info "Root Partition: Remaining space"

    read -p "Do you want to continue? (y/N) " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        error "Operation cancelled by user"
    fi

    sleep 2
}

wipe_partition_table() {
    clear

    log "Wiping existing partition table..."

    local disk="$1"

    wipefs -af "$disk"
    parted -s "$disk" mklabel gpt

    sleep 2
}

disk_partitioning() {
    clear

    log "Disk partitioning on $disk..."

    local disk="$1"
    local swap_size="$2"

    # Create partitions
    local current_position=1

    log "Creating EFI partition..."
    parted -s "$disk" mkpart primary fat32 "${current_position}MiB" "512MiB"
    parted -s "$disk" set 1 esp on
    current_position=512

    log "Creating swap partition..."
    local swap_end=$((current_position + swap_size * 1024))
    parted -s "$disk" mkpart primary linux-swap "${current_position}MiB" "${swap_end}MiB"
    current_position=$swap_end

    log "Create root partition..."
    parted -s "$disk" mkpart primary ext4 "${current_position}MiB" 100%

    # Wait for partitions to be created
    sleep 2
}

disk_formatting() {
    clear

    log "Formatting partitions..."

    local disk="$1"
    local partition_prefix

    if [[ "$disk" =~ "nvme" ]]; then
        partition_prefix="${disk}p"
    else
        partition_prefix="${disk}"
    fi


    info "Formatting EFI partition..."
    mkfs.fat -F32 "${partition_prefix}1"

    info "Formatting swap partition..."
    mkswap "${partition_prefix}2"

    info "Formatting root partition..."
    mkfs.ext4 -F "${partition_prefix}3"

    mount "${partition_prefix}3" /mnt
    mkdir -p /mnt/boot/efi
    mount "${partition_prefix}1" /mnt/boot/efi
    swapon "${partition_prefix}2"

    sleep 2
}

main() {
    enable_pacman_parallel_download
    install_necessary_packages

    local disk=$(select_disk)
    local swap_size=$(select_swap_size)

    confirm_disk_operation "$disk" "$swap_size"

    wipe_partition_table "$disk"
    disk_partitioning "$disk" "$swap_size"
    disk_formatting "$disk"
}

main
