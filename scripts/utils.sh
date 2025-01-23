#!/bin/bash

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp} - LOG  ] $1"
}

warn() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp} - WARN ] $1" >&2
}

error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp} - ERROR] $1"
    exit 1
}

info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp} - INFO ] $1"
}

export -f log
export -f warn
export -f error
export -f info
