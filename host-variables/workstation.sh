#!/bin/bash

export TIMEZONE=Europe/Oslo

export TGTDEV=/dev/nvme0n1
#export SWAP_SIZE=              # Leave uncommented to calculate from total memory

export HOSTNAME=workstation
export DOMAIN=local

export KEYMAP=no-latin1
export EFI=true

export LOCALES=(
    nb_NO
    en_GB
    en_US
)
<<<<<<< HEAD
=======

# export LOCALE_CONF_LANG=en_GB.UTF-8
# export LOCALE_CONF_LC_TIME=en_GB.UTF-8

# One of [intel-ucode, amd-ucode]
export MICROCODE=intel-ucode
>>>>>>> 93713b3 (locale)
