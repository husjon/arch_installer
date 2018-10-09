# vim: ft=sh

export PACKAGES=(
    base
    base-devel

    openssh
    python3
)

export TGTDEV=/dev/nvme0n1
export ROOT_PARTITION_SIZE=64
export SWAP_SIZE=8  # Leave uncommented to calculate from totam memory

export HOSTNAME=laptop
export DOMAIN=local

export KEYMAP=no-latin1

