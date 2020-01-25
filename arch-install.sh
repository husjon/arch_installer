#!/bin/bash

cd "$(dirname "$(realpath "$0")")" || return

# VARIABLES {{{
HOST=${1:-NOT_SET}
STAGE=${2:-NOT_SET}

SCRIPT_DIR=$(pwd)

source ./global-variables.sh
# shellcheck source=host-variables/_template.sh
source "./host-variables/${HOST}.sh"
# }}}

# HELPER FUNCTIONS {{{
info() {
    printf "%s\n" "$*"
}
wait_to_continue() {
    info "Press any key to continue"
    read -r -n 1
    info "\n\n\n"
}
# }}}


# INSTALL
case $STAGE in
    PRE-INSTALL) # {{{
        # setup mirrorlist {{{
            yes | pacman -Sy reflector
            cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

            reflector -c norway -c sweden -p https -f 5 > /etc/pacman.d/mirrorlist || \
            cp /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist
        # }}}
        # set-ntp {{{
            timedatectl set-ntp true
        # }}}
        # partitions {{{
            # pre partition cleanup
            umount -R /mnt
            # shellcheck disable=SC2114
            rm -rf "/mnt/*"

            # script from: https://superuser.com/a/984637
            TOTAL_MEMORY=$(awk '/MemTotal/ {printf "%3.0f", ($2/1024000)}' /proc/meminfo)
            SWAP_SIZE=${SWAP_SIZE:-$TOTAL_MEMORY}

            if [[ -n $EFI ]]; then
            # EFI {{{
                (
                    echo q
                ) | fdisk "${TGTDEV}"

                if [[ ${TGTDEV: -1} =~ [0-9] ]]; then
                    # Sets up the partition device naming (ex. with nvme drives named: /dev/nvme0n1)
                    TGTDEV=${TGTDEV}p
                fi

                # create filesystem and swap
                mkfs.fat  -F32  ${TGTDEV}1
                mkfs.ext4 -F    ${TGTDEV}2
                mkswap          ${TGTDEV}3
                swapon          ${TGTDEV}3
                mkfs.ext4 -F    ${TGTDEV}4

                # mount all the partitions
                mount           ${TGTDEV}2     /mnt

                mkdir -p /mnt/boot/efi
                mount           ${TGTDEV}1     /mnt/boot/efi

                mkdir -p /mnt/home
                mount           ${TGTDEV}4     /mnt/home
            # }}}
            else
            # MBR {{{
            (
                echo o                          # clear the in memory partition table

                echo n                          # new partition
                echo p                          # primary partition type
                echo 1                          # partion number 2
                echo                            # default, start immediately after preceding partition
                echo "+${ROOT_PARTITION_SIZE}G" # 64GB root
                echo y                          # in case the signature already exists, this will remove the previous signature

                echo n                          # new partition
                echo p                          # primary partition type
                echo 2                          # partion number 3
                echo                            # default, start immediately after preceding partition
                echo                            # 8GB swap
                echo y                          # in case the signature already exists, this will remove the previous signature

                echo t                          # partition type
                echo 1                          # partition 2
                echo 83                         # Linux

                echo t                          # partition type
                echo 2                          # partition 3
                echo 82                         # SWAP

                echo p                          # print the in-memory partition table

                echo w                          # write the partition table
            ) | fdisk "${TGTDEV}"
            fi
            if [[ ${TGTDEV: -1} =~ [0-9] ]]; then
                # Sets up the partition device naming (ex. with nvme drives named: /dev/nvme0n1)
                TGTDEV=${TGTDEV}p
            fi

            # create filesystem and swap
            mkfs.ext4 -F    ${TGTDEV}1
            mkswap          ${TGTDEV}2
            swapon          ${TGTDEV}2

            # mount all the partitions
            mount           ${TGTDEV}1     /mnt
            # }}}

        # }}}
        # pacstrap {{{
            pacstrap /mnt "${PACKAGES[@]}"
        # }}}
        # genfstab {{{
            genfstab -U /mnt >> /mnt/etc/fstab
        # }}}
        # arch-chroot {{{
            OUT_FOLDER=$(basename "${SCRIPT_DIR}")

            cp -r "${SCRIPT_DIR}" /mnt

            arch-chroot /mnt "/${OUT_FOLDER}/arch-install.sh" ARCH-CHROOT

            # cleanup
            rm -r "/mnt/${OUT_FOLDER:?}"
        # }}}
    ;; # }}}
    ARCH-CHROOT) # {{{
        # date time {{{
            ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
            hwclock --systohc
        # }}}
        # locale {{{
            cp /etc/locale.gen /tmp/locale.gen
            sed -e 's/#nb_NO/nb_NO/' \
                -e 's/#en_GB/en_GB/' \
                -e 's/#en_US/en_US/' \
                /tmp/locale.gen > /etc/locale.gen
            locale-gen

            cat <<-EOF > /etc/locale.conf
			LANG=en_GB.UTF-8
			LC_TIME=en_GB.UTF-8
			EOF

            echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
        # }}}
        # hostname {{{
            echo "${HOSTNAME}" > /etc/hostname

            cat <<-EOF > /etc/hosts
			127.0.0.1       localhost
			::1             localhost
			127.0.1.1       ${HOSTNAME}.${DOMAIN}   ${HOSTNAME}
			EOF
        # }}}
        # initfsram{{{
            mkinitcpio -p linux
        # }}}
        # bootloader {{{
            if [[ -n $EFI ]]; then
                pacman --noconfirm -S grub intel-ucode efibootmgr
                grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH
            else
                pacman --noconfirm -S grub
                grub-install --bootloader-id=ARCH
            fi
            grub-mkconfig -o /boot/grub/grub.cfg
        # }}}
        # root password{{{
            echo root:password | chpasswd
        # }}}
    ;; # }}}
esac
