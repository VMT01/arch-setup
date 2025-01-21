#!/bin/bash

#######################################################################
# System Configuration Module                                         #
# Description: Basic system configuration for Arch Linux installation #
#######################################################################

readonly DEFAULT_LOCALE="en_US.UTF-8"
readonly DEFAULT_KEYMAP="us"
readonly DEFAULT_TIMEZONE="UTC"

install_base_packages() {
    log "Installing base packages..."

    local base_packages=(
        "grub"
        "efibootmgr"
        "dhcpcd"
        "networkmanager"
        "resolvconf" # Failed here
    )

    pacstrap /mnt "${base_packages[@]}" || error "Failed to install base packages"
}

configure_locale() {
    local locale="${1:-$DEFAULT_LOCALE}"
    local keymap="${2:-$DEFAULT_KEYMAP}"

    log "Configuring locale and keyboard..."

    arch-chroot /mnt bash <<EOF
# Enable locale
echo "${locale} UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=${locale}" > /etc/locale.conf

# Set keyboard layout
echo "KEYMAP=${keymap}" > /etc/vconsole.conf
EOF
}

select_timezone() {
    local timezone=$(tzselect)

    if [[ -z "$timezone" ]]; then
        timezone="${DEFAULT_TIMEZONE}"
    fi

    echo "$timezone"
}

configure_timezone() {
    local timezone="$1"

    log "Configuring timezone..."

    arch-chroot /mnt bash <<EOF
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc
EOF
}

configure_network() {
    local hostname="$1"

    log "Configuring network..."

    echo "$hostname" > /mnt/etc/hostname

    cat > /mnt/etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 ${hostname}
EOF

    arch-chroot /mnt systemctl enable dhcpcd
    arch-chroot /mnt systemctl enable NetworkManager
    arch-chroot /mnt systemctl enable systemd-resolved
}

configure_users() {
    local username="$1"

    log "Configuring users..."

    # Set root password
    log "Setting root password..."
    arch-chroot /mnt passwd

    # Create user and set password
    log "Create user: ${username}"
    arch-chroot /mnt useradd -m -G wheel,storage,power,audio,video -s /bin/bash "$username"
    log "Setting password for ${username}"
    arch-chroot /mnt passwd "${username}"

    # Configure sudo
    log "Configuring sudo access..."
    echo "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/wheel
}

configure_bootloader() {
    log "Installing and configuring bootloader..."

    arch-chroot /mnt bash <<EOF
# Install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --booloader-id=GRUB

# Generate GRUB configuration
grub-mkconfig -o /boot/grub/grub.cfg
EOF
}
