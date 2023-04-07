set -xEeuo pipefail
#mds
mkdir -p /var/lib/ceph/mds/ceph-ceph-node-mon
ceph-authtool --create-keyring /var/lib/ceph/mds/ceph-ceph-node-mon/keyring --gen-key -n mds.ceph-node-mon
ceph auth add mds.ceph-node-mon osd "allow rwx" mds "allow *" mon "allow profile mds" -i /var/lib/ceph/mds/ceph-ceph-node-mon/keyring
chown ceph:ceph /var/lib/ceph/mds/ceph-ceph-node-mon/keyring
systemctl start ceph-mds@ceph-node-mon
systemctl enable ceph-mds@ceph-node-mon
sleep 2
#fs
ceph osd pool create cephfs_data 1
ceph osd pool create cephfs_metadata 1
ceph fs new cephfs cephfs_metadata cephfs_data
ceph fs ls
ceph mds stat
#client secret
ceph auth get-key client.admin > client.admin
#
ceph -s
