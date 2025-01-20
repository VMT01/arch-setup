#!/bin/bash

# Stop immediately if any error occur
set -e

pacman -Syy

source ./setup/partitioning.sh
