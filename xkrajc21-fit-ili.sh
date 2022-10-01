#!/bin/bash

for num in {0..3}
do
	echo -e "\nCreating loop device number $num\n"
	dd if=/dev/zero of=disk$num bs=200MB count=1
	losetup loop$num disk$num
done

echo -e "\nCreating RAID device level 1\n"
yes | mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/loop0 /dev/loop1

echo -e "\nCreating RAID device level 0\n"
yes | mdadm --create /dev/md1 --level=0 --raid-devices=2 /dev/loop2 /dev/loop3

echo -e "\nCreating volume group named FIT_vg\n"
vgcreate FIT_vg /dev/md0 /dev/md1

echo -e "\nCreating logical volumes\n"
lvcreate FIT_vg -n FIT_lv1 -L 100MB
lvcreate FIT_vg -n FIT_lv2 -L 100MB

echo -e "\nCreating EXT4 on FIT_lv1\n"
mkfs.ext4 /dev/FIT_vg/FIT_lv1

echo -e "\nCreating XFS on FIT_lv2\n"
mkfs.xfs /dev/FIT_vg/FIT_lv2

echo -e "\nMounting logical volumes\n"
mkdir /mnt/test1 /mnt/test2
mount /dev/FIT_vg/FIT_lv1 /mnt/test1
mount /dev/FIT_vg/FIT_lv2 /mnt/test2

echo -e "\nResizing FIT_lv1\n"
lvextend -l +100%FREE /dev/FIT_vg/FIT_lv1
resize2fs /dev/FIT_vg/FIT_lv1
df -h

echo -e "\nCreating big_file\n"
dd if=/dev/urandom of=/mnt/test1/big_file bs=1MB count=300
sha512sum /mnt/test1/big_file

echo -e "\nRepairing faulty disk\n"
dd if=/dev/zero of=disk4 bs=200MB count=1
losetup loop4 disk4
mdadm --manage /dev/md0 --fail /dev/loop0
mdadm --manage /dev/md0 --remove /dev/loop0
mdadm --manage /dev/md0 --add /dev/loop4
mdadm --detail /dev/md0
