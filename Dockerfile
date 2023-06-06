FROM scratch 
ADD ixecloud-vrouter-ver0.1-x86-64-generic-rootfs.tar.gz
ADD ./zabbix_agentd.conf /etc/zabbix_agentd.conf
CMD ["/sbin/ash"]