cd $(dirname $(realpath $0))
export SCRIPT_DIR=$(pwd)

# VARIABLES {{{
HOST=${1:-NOT_SET}
STAGE=${2:-NOT_SET}

source ./global-variables.sh
source ./host-variables/${HOST}.sh || exit 1
# }}}

# HELPER FUNCTIONS {{{
info() { printf "$*\n" }
wait_to_continue() { info "Press any key to continue"; read -n 1; info "\n\n\n" }
# }}}


exit 123


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
            rm -rf /mnt/*

            # script from: https://superuser.com/a/984637
            TOTAL_MEMORY=$(awk '/MemTotal/ {printf "%3.0f", ($2/1024000)}' /proc/meminfo)
            SWAP_SIZE=${SWAP_SIZE:-$TOTAL_MEMORY}

            [[ ! -z $EFI ]] && {
            # {{{
            (
                echo q
            ) | fdisk ${TGTDEV}
            # }}}
            } || {
            # MBR {{{
            (
                echo o                          # clear the in memory partition table

                echo n                          # new partition
                echo p                          # primary partition type
                echo 1                          # partion number 2
                echo                            # default, start immediately after preceding partition
                echo +${ROOT_PARTITION_SIZE}G   # 64GB root
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
            ) | fdisk ${TGTDEV}
            # }}}
            }
        # }}}
        # pacstrap {{{
            pacstrap /mnt "${PACKAGES[@]}"
        # }}}
        # genfstab {{{
            genfstab -U /mnt >> /mnt/etc/fstab
        # }}}
        # arch-chroot {{{
            OUT_FOLDER=$(basename ${SCRIPT_DIR})

            cp -r "${SCRIPT_DIR}" /mnt

            arch-chroot /mnt /${OUT_FOLDER}/arch-install.sh ARCH-CHROOT

            # cleanup
            rm -r /mnt/${OUT_FOLDER}
        # }}}
    ;; # }}}
    ARCH-CHROOT) # {{{
        # date time {{{
            ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
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
            [[ ! -z $EFI ]] && {
                pacman --noconfirm -S grub intel-ucode efibootmgr
                grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH
            } || {
                pacman --noconfirm -S grub
                grub-install --bootloader-id=ARCH
            }
            grub-mkconfig -o /boot/grub/grub.cfg
        # }}}
        # root password{{{
            echo root:password | chpasswd
        # }}}
    ;; # }}}
esac
