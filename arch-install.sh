#!/bin/bash

set -e

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
            echo "Server = ${MIRRORLIST}" > /etc/pacman.d/mirrorlist
            sed -i "s/#ParallelDownloads = 5/ParallelDownloads = ${PARALLEL_DOWNLOADS:-5}/" /etc/pacman.conf
        # }}}
        # set-ntp {{{
            timedatectl set-ntp true
        # }}}
        # partitions {{{
            # shellcheck disable=SC2114
            rm -rf "/mnt/*"

            # script from: https://superuser.com/a/984637
            TOTAL_MEMORY=$(awk '/MemTotal/ {printf "%3.0f", ($2/1024000)}' /proc/meminfo)
            SWAP_SIZE=${SWAP_SIZE:-$TOTAL_MEMORY}

            if [ "$EFI" = true ]; then
            # EFI {{{
                (
                    # fdisk {{{
                    echo g                          # clear the in memory partition table

                    echo n                          # new partition
                    echo                            # partition number 1
                    echo                            # default - start at beginning of disk
                    echo +512M                      # 512 MB boot parttion (EFI)
                    echo y                          # in case the signature already exists, this will remove the previous signature

                    echo t                          # partition type
                    echo                            # partition 1
                    echo 1                          # EFI


                    echo n                          # new partition
                    echo                            # Select next partition number
                    echo                            # default, start immediately after preceding partition
                    echo "+${SWAP_SIZE}G"           # 8GB swap
                    echo y                          # in case the signature already exists, this will remove the previous signature

                    echo t                          # partition type
                    echo                            # partition 2
                    echo 19                         # SWAP


                    echo n                          # new partition
                    echo                            # Select next partition number
                    echo                            # default, start immediately after preceding partition
                    echo                            # 64GB root
                    echo y                          # in case the signature already exists, this will remove the previous signature

                    echo t                          # partition type
                    echo                            # partition 2
                    echo 24                         # ROOT

                    echo p                          # print the in-memory partition table

                    echo w                          # write the partition table
                    # }}}
                ) | fdisk ${TGTDEV}

                if [[ ${TGTDEV: -1} =~ [0-9] ]]; then
                    # Sets up the partition device naming (ex. with nvme drives named: /dev/nvme0n1)
                    TGTDEV=${TGTDEV}p
                fi

                # create filesystem and swap
                mkfs.fat  -F32  ${TGTDEV}1

                mkswap          ${TGTDEV}2
                swapon          ${TGTDEV}2
                e2label         ${TGTDEV}2 SWAP

                mkfs.ext4 -F    ${TGTDEV}3
                e2label         ${TGTDEV}3 ROOT

                # mount all the partitions
                mount           ${TGTDEV}3     /mnt

                mkdir -p /mnt/boot
                mount           ${TGTDEV}1     /mnt/boot
            # }}}
            else
            # MBR {{{
            (
                # fdisk {{{
                echo o                          # clear the in memory partition table

                echo n                          # new partition
                echo p                          # primary partition type
                echo                            # Select next partition number
                echo                            # default, start immediately after preceding partition
                echo "+${SWAP_SIZE}G"           # 8GB swap
                echo y                          # in case the signature already exists, this will remove the previous signature

                echo n                          # new partition
                echo p                          # primary partition type
                echo                            # Select next partition number
                echo                            # default, start immediately after preceding partition
                echo                            # 64GB root
                echo y                          # in case the signature already exists, this will remove the previous signature

                echo t                          # partition type
                echo 1                          # partition 2
                echo 83                         # Linux

                echo t                          # partition type
                echo 2                          # partition 3
                echo 82                         # SWAP

                echo p                          # print the in-memory partition table

                echo w                          # write the partition table
                # }}}
            ) | fdisk "${TGTDEV}"
            if [[ ${TGTDEV: -1} =~ [0-9] ]]; then
                # Sets up the partition device naming (ex. with nvme drives named: /dev/nvme0n1)
                TGTDEV=${TGTDEV}p
            fi

            # create filesystem and swap
            mkswap -L SWAP  ${TGTDEV}1
            swapon          ${TGTDEV}1

            mkfs.ext4 -F    ${TGTDEV}2
            e2label         ${TGTDEV}2 ROOT

            # mount all the partitions
            mount           ${TGTDEV}2     /mnt
            # }}}
            fi

        # }}}
        # pacstrap {{{
            pacstrap /mnt "${PACKAGES[@]}"
        # }}}
        # genfstab {{{
            genfstab -U /mnt >> /mnt/etc/fstab
        # }}}
        # arch-chroot {{{
            OUT_FOLDER=$(basename "${SCRIPT_DIR}")

            cp -r "${SCRIPT_DIR}" "/mnt/${OUT_FOLDER}"
            cp /tmp/cacert.pem /mnt/

            arch-chroot /mnt "/${OUT_FOLDER}/arch-install.sh" "${HOST}" ARCH-CHROOT

            cp -r ~/.ssh /mnt/root/

            # cleanup
            rm -r "/mnt/${OUT_FOLDER:?}"
            umount /mnt/boot
            umount /mnt/
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
        # load CA certificate {{{
            trust anchor --store /cacert.pem && rm /cacert.pem
        # }}}
        # initfsram{{{
            mkinitcpio -P
        # }}}
        # bootloader {{{
            bootctl --path=/boot/ install
            cat <<-EOF > /boot/loader/entries/arch.conf
			title   Arch Linux
			linux   /vmlinuz-linux
			initrd  /intel-ucode.img
			initrd  /initramfs-linux.img
			options root=LABEL=ROOT resume=LABEL=SWAP rw
			EOF
        # }}}
        # root password{{{
            echo root:password | chpasswd
        # }}}
        # enable systemd-networkd with enabled DHCP {{{
            cat <<-EOF > /etc/systemd/network/ethernet.network
			[Match]
			Name=*
			[Network]
			DHCP=ipv4
			Domains=local
			EOF
            systemctl enable systemd-networkd
            systemctl enable systemd-resolved
        # }}}
        # enable systemd-networkd with enabled DHCP {{{
            systemctl enable sshd
        # }}}
    ;; # }}}
esac
