#!/bin/bash

export TIMEZONE=Europe/Oslo

export TGTDEV=/dev/vda
#export SWAP_SIZE=              # Leave uncommented to calculate from total memory

export HOSTNAME=packer-arch
export DOMAIN=local

export KEYMAP=no-latin1
export EFI=true

export LOCALES=(
    nb_NO
    en_GB
    en_US
)

# export LOCALE_CONF_LANG=en_GB.UTF-8
# export LOCALE_CONF_LC_TIME=en_GB.UTF-8

# Append extra packages here
PACKAGES+=(
    intel-ucode
    qemu-guest-agent
)

# One of [intel-ucode, amd-ucode]
export MICROCODE=intel-ucode
