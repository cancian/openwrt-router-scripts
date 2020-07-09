umount /dev/sda1
mkfs.ext4 -U 7dda2921-4af7-4e83-9170-92d146366bf3 /dev/sda1
tune2fs -U 7dda2921-4af7-4e83-9170-92d146366bf3 /dev/sda1
mount /dev/sda1 /mnt
tar -C /overlay -cvf - . | tar -C /mnt -xf -
umount /mnt
