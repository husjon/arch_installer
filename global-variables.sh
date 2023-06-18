#!/bin/bash

export PACKAGES=(
    base
    linux
    linux-firmware

    intel-ucode

    openssh
)

export MIRRORS=(
    "https://distro_cache.husjon.xyz/archlinux/\$repo/os/\$arch"
)
export PARALLEL_DOWNLOADS=10
