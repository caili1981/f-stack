# 1.
echo "configure the huge-pages for non-numa node"
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
# or NUMA
#echo 1024 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
#echo 1024 > /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages

mkdir /mnt/huge
mount -t hugetlbfs nodev /mnt/huge
echo 0 > /proc/sys/kernel/randomize_va_space
modprobe uio
insmod /root/src/f-stack/dpdk/x86_64-native-linuxapp-gcc/kmod/rte_kni.ko carrier=on

ifconfig enp0s9 down
insmod ./dpdk/x86_64-native-linuxapp-gcc/kmod/igb_uio.ko
./dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:00:09.0






