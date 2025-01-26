#!/bin/bash

# Strict mode
set -e

SCRIPT_DIR=$(dirname "$0")/scripts

source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/00-pre-install.sh"
source "$SCRIPT_DIR/01-install-base-system.sh"
source "$SCRIPT_DIR/02-configure-base-system.sh"
