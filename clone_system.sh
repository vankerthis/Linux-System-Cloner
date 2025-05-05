#!/bin/bash

# Проверка входных параметров
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <SOURCE> <TARGET_PARTITION>"
    exit 1
fi

SOURCE=$1
TARGET_PARTITION=$2
MOUNT_POINT="/mnt/target"

# Определение типа клонирования
if [ "$SOURCE" == "/" ]; then
    echo "Клонирование загруженной системы..."
    EXCLUDE="--exclude=/dev/* --exclude=/proc/* --exclude=/sys/* --exclude=/tmp/* --exclude=/run/* --exclude=/mnt/* --exclude=/media/* --exclude=/boot"
elif [[ "$SOURCE" == /mnt/* ]]; then
    echo "Клонирование примонтированного раздела..."

    # Проверка структуры системы
    if [ ! -d "$SOURCE/bin" ] || [ ! -d "$SOURCE/etc" ] || [ ! -d "$SOURCE/boot" ]; then
        echo "Ошибка: Источник $SOURCE не содержит базовой структуры системы!"
        exit 1
    fi

    EXCLUDE="--exclude=/boot" # Исключаем только boot
else
    echo "Ошибка: Неверный источник $SOURCE! Используйте '/' или '/mnt/...'"
    exit 1
fi

# Создание точки монтирования, если её нет
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

# Монтирование целевого раздела
sudo mount $TARGET_PARTITION $MOUNT_POINT || { echo "Ошибка: Не удалось смонтировать $TARGET_PARTITION!"; exit 1; }

# Проверка наличия файлов уже после монтирования
if [ "$(ls -A $MOUNT_POINT 2>/dev/null)" ]; then
    echo "Внимание: На $TARGET_PARTITION уже есть файлы."
    echo "Хотите их удалить, чтобы создать точный клон? (y/n)"
    read USE_DELETE
else
    echo "Целевой раздел пуст, клонирование начнётся без удаления."
    USE_DELETE="n"
fi

# Если пользователь выбрал "y", добавляем --delete
if [ "$USE_DELETE" == "y" ]; then
    DELETE_FLAG="--delete"
else
    DELETE_FLAG=""
fi

# Копирование данных
echo "Копирование данных из $SOURCE в $MOUNT_POINT..."
sudo rsync -aAXv $DELETE_FLAG $SOURCE/ $MOUNT_POINT/ $EXCLUDE || { echo "Ошибка: Копирование завершилось неудачей!"; sudo umount $MOUNT_POINT; exit 1; }

# Обновление только строки с root (`/`) в fstab
UUID_CLONE=$(sudo blkid -s UUID -o value $TARGET_PARTITION)
sudo sed -i "s|^UUID=.* / ext4 .*|UUID=$UUID_CLONE / ext4 defaults 0 1|" $MOUNT_POINT/etc/fstab

# Получение имени диска (например, sda из sda4)
DISK_NAME=$(echo "$TARGET_PARTITION" | sed 's/[0-9]*$//')

# Установка GRUB внутри клона
sudo mount --bind /dev $MOUNT_POINT/dev
sudo mount --bind /proc $MOUNT_POINT/proc
sudo mount --bind /sys $MOUNT_POINT/sys

sudo chroot $MOUNT_POINT grub-install --boot-directory=/boot "$DISK_NAME"
sudo chroot $MOUNT_POINT update-grub

sudo umount $MOUNT_POINT/dev
sudo umount $MOUNT_POINT/proc
sudo umount $MOUNT_POINT/sys

# Завершение
sudo umount $MOUNT_POINT
echo "Клонирование завершено успешно!"
