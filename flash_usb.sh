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
            Logger $GREEN "DONE !"
            Logger $GREEN "Prompting now result:" 
            sudo fdisk -l $USB_DEVICE
        
        else
            Logger $MAGENTA "ABORTED."
            exit 1;
        fi
    fi
}

flash_image_on_usb()
{
    
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
