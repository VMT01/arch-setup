#!/bin/bash

#####################################################################
# Utility functions                                                 #
# Description: Common utility functions for Arch Linux installation #
#####################################################################

# Color codes for output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # Reset color

#############################
#     Logging Functions     #
#############################

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[+] ${timestamp} - $1${NC}"
}

warn() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[!] ${timestamp} - $1${NC}" >&2
}

error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[-] ${timestamp} - $1${NC}" >&2
    exit 1
}

info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[*] ${timestamp} - $1${NC}"
}

##############################
#     Validate Functions     #
##############################

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root!"
    fi
}

readonly PACMAN_CONF="/etc/pacman.conf"
enable_pacman_parallel() {
    # Create backup file
    if [ ! -f "${PACMAN_CONF}.bak" ]; then
        cp "$PACMAN_CONF" "${PACMAN_CONF}.bak"
        info "Backed up pacman config at ${PACMAN_CONF}.bak"
    fi

    # Add ParallelDownloads config
    if grep -q "^#ParallelDownloads" "$PACMAN_CONF"; then
        sed -i 's/^#ParallelDownloads/ParallelDownloads/' "$PACMAN_CONF"
        log "Parallel Download enable success"
    elif grep -q "^ParallelDownloads" "$PACMAN_CONF"; then
        info "Parallel Download already enabled"
    else
        warn "ParallelDownloads not found in $PACMAN_CONF. Adding configuration..."
        echo -e "\n# Enable parallel downloads\nParallelDownloads = 5" >> "$PACMAN_CONF"
        log "Added ParallelDownloads configuration with default value is 5"
    fi
}

install_necessary_packages() {
    local packages=(
        "fzf"
    )

    pacman -S "${packages[@]}" --noconfirm --needed || error "Failed to install neccessary packages"
}
