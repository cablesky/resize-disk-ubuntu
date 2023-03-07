#!/bin/bash

# on Proxmox node:
# resize disk of vm (VM - Hardware - Hard Disk - Resize Disk)
# note: guest vm may be started (resizing while running is possible)

# on guest vm:

echo "- Check lvm config before"
sudo pvs
echo __
sudo vgs
echo __
sudo lvs
echo ___

echo "- Check disk space before"
df -h | grep -E 'Size|vg'
echo ___

device=$(sudo pvs -o pv_name --noheadings | sed -e "s/^ *\/dev\///" -e "s/[0-9]* *$//")
echo "device=$device"

partition=$(sudo pvs -o pv_name --noheadings | sed -e "s/^ *\/dev\///" -e "s/^[a-z]*//")
echo "partition=$partition"

fsmountsource=$(findmnt / -o SOURCE --noheadings)
echo "fsmountsource=$fsmountsource"
echo ___

echo "- Check if change of disk size is detected"
dmesg | grep $device
echo ___

echo "- Print partition table"
sudo fdisk -l /dev/$device | grep ^/dev
echo ___

read -p "Press [Enter] to resize partition"

if sudo gdisk -l /dev/$device | grep "GPT: present";
then
  echo "- Move GPT second header to end of disk"
  sudo sgdisk /dev/$device -e
fi

echo "- Resize partition"
sudo parted /dev/$device resizepart $partition 100%
echo ___

echo "- Check the new partition table"
sudo fdisk -l /dev/$device | grep ^/dev
echo ___

echo "- Resize lvm physical volume"
sudo pvresize /dev/$device$partition
echo ___

echo "- Resize the lvm logical volume and the filesystem"
sudo lvresize --extents +100%FREE --resizefs $fsmountsource
echo ___

echo "- Check lvm config afterwards"
sudo pvs
echo __
sudo vgs
echo __
sudo lvs
echo ___

echo "- Check disk space afterwards"
df -h | grep -E 'Size|vg'
