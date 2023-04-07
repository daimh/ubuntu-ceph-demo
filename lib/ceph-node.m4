set -xEeuo pipefail
hostname ceph-node-m4Hostname
hostname > /etc/hostname
ip l s ens4 up
ip a a 192.168.111.m4Id/24 dev ens4
for ((i=1; ; i++)); do ! ping -c 1 192.168.111.1 || break; sleep 2; echo "MSG-001: ping, retry $i"; done
grep -q ceph /etc/hosts || cat >> /etc/hosts << __EOF
192.168.111.1	ceph-node-mon
192.168.111.2	ceph-node-osd1
192.168.111.3	ceph-node-osd2
__EOF
