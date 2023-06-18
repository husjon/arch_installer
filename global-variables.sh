#!/bin/bash

export PACKAGES=(
    base
    base-devel
    linux
    linux-firmware

    intel-ucode

    openssh
    python
)

export MIRRORS=(
    "https://distro_cache.husjon.xyz/archlinux/\$repo/os/\$arch"
)
export PARALLEL_DOWNLOADS=10
