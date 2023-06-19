# Arch Installer
A simple installer for Arch Linux

Originally started on it back in 2018 and has been changing ever since.
I've been primarily using it when building VMs with [Packer](https://www.packer.io/)



### Pre-requisite:
* A new bare metal or virtual machine
* Booted an Arch ISO
* Internet access (can be avoided with f.ex preloading a USB with the installer)



### Usage:
1. When the ISO has been booted run the following commands:
    ```bash
    cd /tmp
    wget https://github.com/husjon/arch_installer/archive/refs/tags/v0.2.0.tar.gz
    tar xfzv v0.2.0.tar.gz
    cd arch_installer-v0.2.0
    ```
2. Copy `_template.sh` in `host-variables` and make any changes you see fit.
3. When done, run the following command, replacing `<HOSTNAME>` with the name of the file you copied.
    The `.sh` extension should be omitted.
    ```bash
    ./arch-install.sh <HOSTNAME> INSTALL
    ```
4. The installer will now run through lall the steps.



### What the installer does.
1. Loads in `global-variables` and a `host-variables` based on the input arguments.
2. Updates the mirror (if set).
3. Formats and partitions the disk defined in the `host-variable`.
4. Runs `pacstrap` with the packages defined in both `global-variables` and the `host-variable`
5. When the `pacstrap` finishes it uses `arch-chroot` to run the finalizing steps
   1. Set timezone
   2. Sets and generates locale and keymap
   3. Sets the hostname
   4. Creates a new initramfs
   5. Sets up the bootloader
   6. Sets a default password of the root user
   7. Enables `systemd-networkd` and `systemd-resolved`
   8. Enables `sshd`

After all this, the only requires step is to reboot the machine and shortly after it should be booting into the new installation.
