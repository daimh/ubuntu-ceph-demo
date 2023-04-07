set -xEeuo pipefail
apt -y install ceph-osd
fallocate -l 10G loop9.img
losetup loop9 loop9.img
cp keys.d/ceph.keyring /var/lib/ceph/bootstrap-osd/
cp keys.d/ceph.client.admin.keyring /etc/ceph/ceph.keyring
cp keys.d/ceph.conf /etc/ceph/
ceph-volume raw prepare --bluestore --data /dev/loop9 
ID=$(ceph-volume raw list |grep osd_id |cut -d : -f 2 | tr -d ", ")
systemctl start ceph-osd@$ID.service
cat > ceph-osd-start.sh << __EOF
losetup loop9 loop9.img
cp ceph.keyring /var/lib/ceph/osd/ceph-$ID/keyring
chown ceph:ceph /var/lib/ceph/osd/ceph-$ID/keyring
systemctl start ceph-osd@$ID.service
__EOF
ceph -s
