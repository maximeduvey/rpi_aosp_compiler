#!/bin/bash

# Define some color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m' # No Color

Logger() {
    color=$1
    echo -e "${color}$2${RESET}"
}

usage() {
    Logger $BLUE "Usage: $0 -u [usb device path /dev/sdb]"
    echo "Please execute this script at the root of you android folder"
    exit 1
}

clear_partition()
{
    Logger $RED "Clearing partition $USB_DEVICE"
    sudo umount $USB_DEVICE*
    sudo wipefs -a $USB_DEVICE
}

detecting_usb_partition()
{
    Logger $GREEN "Checking USB partition for $USB_DEVICE"
    PARTITION_COUNT=$(ls ${USB_DEVICE}? 2> /dev/null | wc -l)
    echo "Detected nbr partiton: $PARTITION_COUNT"

    if [ $PARTITION_COUNT -ne 4 ]; then
        Logger $RED "Error: The device $USB_DEVICE does not have exactly 4 partitions."
        Logger $RED "We will erase the $USB_DEVICE partitions to create 4 disk."
        read -p "Please confirm y/n" choice;echo
        if [ $choice == "y" ]; then
            Logger $BLUE "Formatting partition"
            sudo true
            clear_partition
            echo -e "n\np\n1\n\n+128M\na\n1\nt\n1\n0c\nn\np\n2\n\n+2G\nn\np\n3\n\n+128M\nn\np\n\n\nw" | sudo fdisk "$USB_DEVICE"
            sleep 1
            Logger $GREEN "DONE !"
            Logger $GREEN "Prompting now result:" 
            sudo fdisk -l $USB_DEVICE
            sleep 1

            sudo mkdosfs -F 32 "$USB_DEVICE"1
            sudo mkfs.ext4 -L userdata "$USB_DEVICE"4
            sleep 1
        
        else
            Logger $MAGENTA "ABORTED."
            exit 1;
        fi
    fi
}

flash_image_on_usb() {
    # Exit immediately if a command exits with a non-zero status

    sleep 1
    sudo umount $USB_DEVICE*
    Logger $BLUE "Will mount and flash partition"

    set -e
    # Each command is checked for a successful exit status
    sudo rm -rf /mnt/p1 || { echo "Failed to remove /mnt/p1"; return 1; }
    sudo mkdir -p /mnt/p1 || { echo "Failed to create /mnt/p1"; return 1; }
    sudo mount "$USB_DEVICE"1 /mnt/p1 || { echo "Mount failed"; return 1; }
    sudo mkdir -p /mnt/p1/overlays || { echo "Failed to create /mnt/p1/overlays"; return 1; }
    Logger $BLUE "boot copy"
    sudo cp device/arpi/rpi4/boot/* /mnt/p1 || { echo "Failed to copy boot files"; return 1; }
    sleep 1
    Logger $BLUE "Image.gz copy"
    sudo cp kernel/arpi/arch/arm64/boot/Image.gz /mnt/p1 || { echo "Failed to copy Image.gz"; return 1; }
    Logger $BLUE "bcm...dtb"
    sudo cp kernel/arpi/arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb /mnt/p1 || { echo "Failed to copy bcm2711-rpi-4-b.dtb"; return 1; }
    Logger $BLUE "bcm...dtbo copy"
    sleep 1
    sudo cp kernel/arpi/arch/arm/boot/dts/overlays/vc4-kms-v3d-pi4.dtbo /mnt/p1/overlays/ || { echo "Failed to copy vc4-kms-v3d-pi4.dtbo"; return 1; }
    Logger $BLUE "ramdisk copy"
    sudo cp out/target/product/rpi4/ramdisk.img /mnt/p1 || { echo "Failed to copy ramdisk.img"; return 1; }
    Logger $BLUE "done"
    sudo umount /mnt/p1 || { echo "Unmount /mnt/p1 failed"; return 1; }
    cd out/target/product/rpi4/ || { echo "Failed to change directory"; return 1; }
    Logger $BLUE "flashing system copy"
    sudo dd if=system.img of="$USB_DEVICE"2 bs=1M status=progress || { echo "Failed to write system.img"; return 1; }
    Logger $BLUE "flashing vendor copy"
    sudo dd if=vendor.img of="$USB_DEVICE"3 bs=1M status=progress || { echo "Failed to write vendor.img"; return 1; }
    Logger $GREEN "Success"
    cd -

    # Reset the -e option if needed for the rest of the script
    set +e
}

if [ $# -eq 0 ]; then
    echo "Error: No arguments provided."
    usage
fi

# Parse the arguments
  while getopts "u:e:" option
    do
        #echo "getopts a trouvé l'option $option"
        case $option in
        u)
            USB_DEVICE="$OPTARG"
            #echo "-> $USB_DEVICE"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Check if the USB device argument is provided
# if [ -z "$USB_DEVICE" ]; then
#     echo "Error: USB $USB_DEVICE device not specified."
#     usage
#     exit 1;
# fi

WORKSPACE=$PWD

detecting_usb_partition

flash_image_on_usb
set +e