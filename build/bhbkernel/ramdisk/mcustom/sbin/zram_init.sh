#!/system/bin/sh

zramstate=`cat /sys/block/zram0/initstate`;
zramcat=`cat /sys/block/zram0/max_comp_streams`;
echo 'zram_cat before max_comp_streams = ' $zramcat ' initstate =' $zramstate> /dev/kmsg;

echo 0 > /proc/sys/vm/page-cluster
echo 4 > /sys/block/zram0/max_comp_streams
echo 536870912 > /sys/block/zram0/disksize
mkswap /dev/block/zram0
swapon /dev/block/zram0

zramstate=`cat /sys/block/zram0/initstate`;
zramcat=`cat /sys/block/zram0/max_comp_streams`;
echo 'zram_cat after swapon max_comp_streams = ' $zramcat ' initstate =' $zramstate> /dev/kmsg;

exit
