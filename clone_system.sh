#!/bin/bash

# Checking input parameters
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <SOURCE> <TARGET_PARTITION>"
    exit 1
fi

SOURCE=$1
TARGET_PARTITION=$2
MOUNT_POINT="/mnt/target"

# Determining cloning type
if [ "$SOURCE" == "/" ]; then
    echo "Cloning the running system..."
    EXCLUDE="--exclude=/dev/* --exclude=/proc/* --exclude=/sys/* --exclude=/tmp/* --exclude=/run/* --exclude=/mnt/* --exclude=/media/* --exclude=/boot"
elif [[ "$SOURCE" == /mnt/* ]]; then
    echo "Cloning a mounted partition..."

    # Checking system structure
    if [ ! -d "$SOURCE/bin" ] || [ ! -d "$SOURCE/etc" ] || [ ! -d "$SOURCE/boot" ]; then
        echo "Error: The source $SOURCE does not contain a basic system structure!"
        exit 1
    fi

    EXCLUDE="--exclude=/boot" # Excluding only boot
else
    echo "Error: Invalid source $SOURCE! Use '/' or '/mnt/...'"
    exit 1
fi

# Creating the mount point if it does not exist
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

# Mounting the target partition
sudo mount $TARGET_PARTITION $MOUNT_POINT || { echo "Error: Failed to mount $TARGET_PARTITION!"; exit 1; }

# Checking for existing files after mounting
if [ "$(ls -A $MOUNT_POINT 2>/dev/null)" ]; then
    echo "Warning: $TARGET_PARTITION already contains files."
    echo "Do you want to delete them to create an exact clone? (y/n)"
    read USE_DELETE
else
    echo "Target partition is empty, cloning will proceed without deletion."
    USE_DELETE="n"
fi

# If the user chose "y", add --delete option
if [ "$USE_DELETE" == "y" ]; then
    DELETE_FLAG="--delete"
else
    DELETE_FLAG=""
fi

# Copying data
echo "Copying data from $SOURCE to $MOUNT_POINT..."
sudo rsync -aAXv $DELETE_FLAG $SOURCE/ $MOUNT_POINT/ $EXCLUDE || { echo "Error: Copying failed!"; sudo umount $MOUNT_POINT; exit 1; }

# Updating only the root (`/`) entry in fstab
UUID_CLONE=$(sudo blkid -s UUID -o value $TARGET_PARTITION)
sudo sed -i "s|^UUID=.* / ext4 .*|UUID=$UUID_CLONE / ext4 defaults 0 1|" $MOUNT_POINT/etc/fstab

# Extracting disk name (e.g., "sda" from "sda4")
DISK_NAME=$(echo "$TARGET_PARTITION" | sed 's/[0-9]*$//')

# Installing GRUB inside the clone
sudo mount --bind /dev $MOUNT_POINT/dev
sudo mount --bind /proc $MOUNT_POINT/proc
sudo mount --bind /sys $MOUNT_POINT/sys

sudo chroot $MOUNT_POINT grub-install --boot-directory=/boot "$DISK_NAME"
sudo chroot $MOUNT_POINT update-grub

sudo umount $MOUNT_POINT/dev
sudo umount $MOUNT_POINT/proc
sudo umount $MOUNT_POINT/sys

# Finalizing
sudo umount $MOUNT_POINT
echo "Cloning completed successfully!"
