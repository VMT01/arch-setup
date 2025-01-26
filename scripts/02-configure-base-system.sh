#!/bin/bash

readonly DEFAULT_TIMEZONE="UTC"
readonly DEFAULT_HOSTNAME="arch-linux"
readonly DEFAULT_USERNAME="arch"

configure_locale() {
    log "Configuring locale..."

    arch-chroot /mnt bash <<EOF
sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
EOF
}

configure_timezone() {
    log "Configuring timezone..."

    local timezone=$(tzselect)

    if [[ -z "$timezone" ]]; then
        timezone="${DEFAULT_TIMEZONE}"
    fi

    arch-chroot /mnt bash <<EOF
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc
EOF
}

configure_system_hostname() {
    log "Configuring system hostname..."

    local hostname="$1:-$DEFAULT_HOSTNAME"
    echo "$hostname" > /mnt/etc/hostname

    cat > /mnt/etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 $hostname
EOF
}

configure_user() {
    log "Configuring user..."

    info "Setting password for root"
    arch-chroot /mnt passwd root

    local username=${1:-$DEFAULT_USERNAME}
    info "Create user: ${username}"
    arch-chroot /mnt useradd -m -G wheel,storage,power,audio,video -s /bin/bash "$username"
    info "Setting password for ${username}"
    arch-chroot /mnt passwd "${username}"

    sed -i 's/^# \(%wheel ALL=(ALL:ALL) ALL\)/\1/' /mnt/etc/sudoers
}

configure_bootloader() {
    log "Configuring boot loader..."

    local packages=(
        "grub"       # Bootloader to manage and load operating systems
        "efibootmgr" # Manage EFI boot entries and boot order
    )

    pacstrap /mnt "${packages[@]}" || error "Failed to install bootloader dependencies"
    arch-chroot /mnt bash <<EOF
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF
}

configure_network() {
    log "Configuring network..."

    local packages=(
        "dhcpcd"
        "networkmanager"
        "resolvconf"
    )

    pacstrap /mnt "${packages[@]}" || error "Failed to install network dependencies"
    arch-chroot /mnt bash <<EOF
systemctl enable dhcpcd
systemctl enable NetworkManager
systemctl enable systemd-resolved
EOF
}

main() {
    configure_locale
    configure_timezone

    read -p "Enter your hostname (default=$DEFAULT_HOSTNAME): " hostname
    configure_system_hostname $hostname

    read -p "Enter your username (default=$DEFAULT_USERNAME): " username
    configure_user

    configure_bootloader
    configure_network
}

main
