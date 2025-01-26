#!/bin/bash

install_base_system_packages() {
    clear

    log "Installing base packages..."

    local packages=(
        "base"              # Core system management tools and utilities
        "base-devel"        # Compilation and development toolchain
        "linux"             # Kernel managing hardware and system resources
        "linux-firmware"    # Drivers and firmware for peripheral devices
        # "sudo"
        # "vim"
    )

    pacstrap /mnt "${packages[@]}" || error "Failed to install base packages"

    sleep 2
}

generate_fstab() {
    clear

    log "Generating fstab..."

    genfstab -U -p /mnt > /mnt/etc/fstab

    sleep 2
}

main() {
    install_base_system_packages
    generate_fstab
}

main
