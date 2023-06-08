FROM scratch 
ADD openwrt-x86-64-generic-ext4-rootfs.img.gz
ADD ./zabbix_agentd.conf /etc/zabbix_agentd.conf
CMD ["/sbin/ash"]