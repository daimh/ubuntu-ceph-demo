set -xEeuo pipefail
hostname ceph-node-m4Hostname
hostname > /etc/hostname
ip l s ens4 up
ip a a 192.168.111.1m4Id/24 dev ens4
for ((i=1; ; i++)); do ! ping -c 1 192.168.111.10 || break; sleep 2; echo "MSG-001: ping, retry $i"; done
grep -q ceph /etc/hosts || cat >> /etc/hosts << __EOF
192.168.111.10	ceph-node-mon
192.168.111.11	ceph-node-osd1
192.168.111.12	ceph-node-osd2
192.168.111.13	ceph-node-filesystem
192.168.111.14	ceph-node-rbd
__EOF
